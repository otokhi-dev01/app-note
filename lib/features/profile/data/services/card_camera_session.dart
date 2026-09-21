import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Note/core/services/native_media_services.dart';

/// Owns a single camera lifetime. A fresh session is used after app resume.
class CardCameraSession {
  CardCameraSession({this.lensIndex = 0});

  final int lensIndex;
  int cameraCount = 0;
  CameraController? _camera;
  bool _closed = false;
  bool _readingFrame = false;
  int _streamGeneration = 0;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  Size viewport = Size.zero;
  Rect frame = Rect.zero;

  Future<void> initialize() async {
    final cameras = (await availableCameras()).toList();
    cameras.sort(
      (a, b) => (a.lensDirection == CameraLensDirection.back ? 0 : 1).compareTo(
        b.lensDirection == CameraLensDirection.back ? 0 : 1,
      ),
    );
    cameraCount = cameras.length;
    final rear = cameras.where(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
    if (rear.isEmpty) {
      throw CameraException('NoCamera', 'No rear camera is available.');
    }
    if (_closed) return;
    final camera = CameraController(
      cameras[lensIndex % cameras.length],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420,
    );
    _camera = camera;
    await camera.initialize();
    if (_closed) return;
    await camera.setFlashMode(FlashMode.off);
  }

  Widget buildPreview() {
    final camera = _camera;
    if (_closed || camera == null) return const SizedBox.expand();
    return ValueListenableBuilder<CameraValue>(
      valueListenable: camera,
      builder: (context, value, _) {
        final size = value.previewSize;
        if (_closed ||
            camera != _camera ||
            !value.isInitialized ||
            size == null ||
            size.isEmpty) {
          return const SizedBox.expand();
        }
        final landscape =
            value.deviceOrientation == DeviceOrientation.landscapeLeft ||
            value.deviceOrientation == DeviceOrientation.landscapeRight;
        return ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: landscape ? size.width : size.height,
                height: landscape ? size.height : size.width,
                child: CameraPreview(camera),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> setTorch(bool enabled) async {
    await _camera?.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
  }

  Future<void> focus(Offset point) async {
    await _camera?.setFocusPoint(point);
    await _camera?.setExposurePoint(point);
  }

  Future<void> startDetection(ValueChanged<String> onText) async {
    final camera = _camera;
    if (_closed || camera == null || camera.value.isStreamingImages) return;
    final generation = ++_streamGeneration;
    await camera.startImageStream((image) {
      if (_closed ||
          _readingFrame ||
          generation != _streamGeneration ||
          viewport.isEmpty ||
          frame.isEmpty ||
          DateTime.now().difference(_lastFrame).inMilliseconds < 1100) {
        return;
      }
      if (image.format.group != ImageFormatGroup.bgra8888 &&
          image.format.group != ImageFormatGroup.yuv420 &&
          image.format.group != ImageFormatGroup.nv21) {
        return;
      }
      _readingFrame = true;
      _lastFrame = DateTime.now();
      final plane = image.planes.first;
      final deviceRotation = switch (camera.value.deviceOrientation) {
        DeviceOrientation.portraitUp => 0,
        DeviceOrientation.landscapeLeft => 90,
        DeviceOrientation.portraitDown => 180,
        DeviceOrientation.landscapeRight => 270,
      };
      // AVFoundation rotates its video output; CameraX delivers sensor buffers.
      final rotation = Platform.isIOS
          ? 0
          : (camera.description.sensorOrientation - deviceRotation + 360) % 360;
      final data = CardCameraFrame(
        bytes: Uint8List.fromList(plane.bytes),
        width: image.width,
        height: image.height,
        rowStride: plane.bytesPerRow,
        pixelStride:
            plane.bytesPerPixel ??
            (image.format.group == ImageFormatGroup.bgra8888 ? 4 : 1),
        bgra: image.format.group == ImageFormatGroup.bgra8888,
        rotation: rotation,
        viewport: viewport,
        frame: frame,
      );
      unawaited(_readFrame(data, generation, onText));
    });
  }

  Future<void> _readFrame(
    CardCameraFrame data,
    int generation,
    ValueChanged<String> onText,
  ) async {
    Directory? temporary;
    try {
      final bytes = await compute(encodeCardCameraFrame, data);
      if (_closed || generation != _streamGeneration) return;
      temporary = await (await getTemporaryDirectory()).createTemp(
        'card_frame_',
      );
      final file = await File(
        '${temporary.path}/frame.jpg',
      ).writeAsBytes(bytes);
      final text = await NativeMediaServices.recognizeText(file.path);
      if (!_closed && generation == _streamGeneration) onText(text);
    } catch (_) {
      // A blurred frame is retried on the next sample; the shutter remains usable.
    } finally {
      if (temporary != null) await _removeTemporary(temporary);
      _readingFrame = false;
    }
  }

  Future<void> stopDetection() async {
    _streamGeneration++;
    final camera = _camera;
    if (camera != null && camera.value.isStreamingImages) {
      await camera.stopImageStream();
    }
  }

  /// Retains the photo for identity review/upload; the caller owns its lifetime.
  Future<String> capturePhoto() async {
    final camera = _camera;
    if (_closed || camera == null || !camera.value.isInitialized) {
      throw CameraException('CameraUnavailable', 'The camera is not ready.');
    }
    await stopDetection();
    // Backgrounding or leaving the screen can dispose the session while the
    // image stream is stopping. Never read a new or cleared controller here.
    if (_closed || camera != _camera || !camera.value.isInitialized) {
      throw CameraException('CameraUnavailable', 'The camera was closed.');
    }
    final captureViewport = viewport;
    final captureFrame = frame;
    if (captureViewport.isEmpty || captureFrame.isEmpty) {
      throw CameraException(
        'CameraUnavailable',
        'The card guide is not ready.',
      );
    }
    final source = File((await camera.takePicture()).path);
    final cropped = File('${source.path}_card.jpg');
    try {
      final bytes = await compute(cropCardCameraPhoto, (
        bytes: await source.readAsBytes(),
        viewport: captureViewport,
        frame: captureFrame,
      ));
      if (_closed || camera != _camera) {
        throw CameraException('CameraUnavailable', 'The camera was closed.');
      }
      await cropped.writeAsBytes(bytes, flush: true);
      if (_closed || camera != _camera) {
        throw CameraException('CameraUnavailable', 'The camera was closed.');
      }
      return cropped.path;
    } catch (_) {
      await _removeTemporary(cropped);
      rethrow;
    } finally {
      await _removeTemporary(source);
    }
  }

  Future<String> captureText() async {
    final path = await capturePhoto();
    try {
      return await NativeMediaServices.recognizeText(path);
    } finally {
      await _removeTemporary(File(path));
    }
  }

  Future<void> dispose() async {
    _closed = true;
    _streamGeneration++;
    final camera = _camera;
    _camera = null;
    await camera?.dispose();
  }

  static Future<String?> pickText() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (image == null) return null;
    // The photo library owns the original; do not delete the selected image.
    return NativeMediaServices.recognizeText(image.path);
  }
}

Future<void> _removeTemporary(FileSystemEntity entity) async {
  try {
    await entity.delete(recursive: entity is Directory);
  } on FileSystemException {
    // Cleanup must not replace an OCR result or camera error.
  }
}

@immutable
class CardCameraFrame {
  const CardCameraFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.rowStride,
    required this.pixelStride,
    required this.bgra,
    required this.rotation,
    required this.viewport,
    required this.frame,
  });
  final Uint8List bytes;
  final int width, height, rowStride, pixelStride, rotation;
  final bool bgra;
  final Size viewport;
  final Rect frame;
}

/// Convert only luminance for OCR, respecting padded rows on both platforms.
/// This runs off the UI isolate and crops to the blue guide in the preview.
Uint8List encodeCardCameraFrame(CardCameraFrame data) {
  final sample = math.max(1, (math.max(data.width, data.height) / 1280).ceil());
  var image = img.Image(
    width: data.width ~/ sample,
    height: data.height ~/ sample,
    numChannels: 1,
  );
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final offset =
          y * sample * data.rowStride + x * sample * data.pixelStride;
      final value = data.bgra
          ? (data.bytes[offset] * 0.114 +
                    data.bytes[offset + 1] * 0.587 +
                    data.bytes[offset + 2] * 0.299)
                .round()
          : data.bytes[offset];
      image.setPixelR(x, y, value);
    }
  }
  if (data.rotation != 0) image = img.copyRotate(image, angle: data.rotation);
  final crop = cardFrameCrop(
    Size(image.width.toDouble(), image.height.toDouble()),
    data.viewport,
    data.frame,
  );
  image = img.copyCrop(
    image,
    x: crop.left.floor(),
    y: crop.top.floor(),
    width: math.max(1, crop.width.floor()),
    height: math.max(1, crop.height.floor()),
  );
  return img.encodeJpg(image, quality: 88);
}

/// Saves only the area inside the guide, at the still photo's resolution.
/// Bake EXIF orientation before mapping the preview's cover transform.
Uint8List cropCardCameraPhoto(
  ({Uint8List bytes, Size viewport, Rect frame}) data,
) {
  if (data.viewport.isEmpty || data.frame.isEmpty) {
    throw const FormatException('Missing card guide');
  }
  if (data.bytes.isEmpty) throw const FormatException('Unreadable card photo');
  final decoded = img.decodeImage(data.bytes);
  if (decoded == null) throw const FormatException('Unreadable card photo');
  final photo = img.bakeOrientation(decoded);
  final crop = cardFrameCrop(
    Size(photo.width.toDouble(), photo.height.toDouble()),
    data.viewport,
    data.frame,
  );
  final left = crop.left.ceil();
  final top = crop.top.ceil();
  final width = crop.right.floor() - left;
  final height = crop.bottom.floor() - top;
  if (width < 1 || height < 1) {
    throw const FormatException('Card guide is outside the photo');
  }
  return img.encodeJpg(
    img.copyCrop(photo, x: left, y: top, width: width, height: height),
    quality: 95,
  );
}

/// Maps the visible guide through the same cover transform as CameraPreview.
Rect cardFrameCrop(Size image, Size viewport, Rect frame) {
  final scale = math.max(
    viewport.width / image.width,
    viewport.height / image.height,
  );
  final dx = (image.width * scale - viewport.width) / 2;
  final dy = (image.height * scale - viewport.height) / 2;
  return Rect.fromLTRB(
    (frame.left + dx) / scale,
    (frame.top + dy) / scale,
    (frame.right + dx) / scale,
    (frame.bottom + dy) / scale,
  ).intersect(Offset.zero & image);
}
