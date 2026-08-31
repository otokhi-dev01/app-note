import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Places one image over another before handing the flattened result to the
/// native iOS markup editor.
class ImageOverlayComposerPage extends StatefulWidget {
  final String baseImagePath;
  final String overlayImagePath;

  const ImageOverlayComposerPage({
    super.key,
    required this.baseImagePath,
    required this.overlayImagePath,
  });

  @override
  State<ImageOverlayComposerPage> createState() =>
      _ImageOverlayComposerPageState();
}

class _ImageOverlayComposerPageState extends State<ImageOverlayComposerPage> {
  ui.Image? _baseImage;
  ui.Image? _overlayImage;
  Object? _loadError;
  bool _isSaving = false;

  Offset _center = const Offset(0.5, 0.5);
  double _widthFraction = 0.42;
  Offset _gestureStartCenter = Offset.zero;
  Offset _gestureStartFocalPoint = Offset.zero;
  double _gestureStartWidthFraction = 0.42;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final images = await Future.wait([
        _decodeImage(widget.baseImagePath),
        _decodeImage(widget.overlayImagePath),
      ]);
      if (!mounted) {
        for (final image in images) {
          image.dispose();
        }
        return;
      }
      setState(() {
        _baseImage = images[0];
        _overlayImage = images[1];
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<ui.Image> _decodeImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  void dispose() {
    _baseImage?.dispose();
    _overlayImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 88,
        leading: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        title: const Text('Add Image'),
        centerTitle: true,
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: _isSaving || _baseImage == null ? null : _save,
            child: _isSaving
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text('Continue'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildCanvas()),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: Text(
                'Drag to move • Pinch to resize',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    if (_loadError != null) {
      return const Center(
        child: Text(
          'Could not open those images',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    final baseImage = _baseImage;
    final overlayImage = _overlayImage;
    if (baseImage == null || overlayImage == null) {
      return const Center(child: CupertinoActivityIndicator(radius: 15));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = _fitSize(
          Size(baseImage.width.toDouble(), baseImage.height.toDouble()),
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        final overlaySize = _overlaySize(canvasSize);
        final left = _center.dx * canvasSize.width - overlaySize.width / 2;
        final top = _center.dy * canvasSize.height - overlaySize.height / 2;

        return Center(
          child: SizedBox.fromSize(
            size: canvasSize,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: RawImage(image: baseImage, fit: BoxFit.fill),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: overlaySize.width,
                  height: overlaySize.height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (details) {
                      _gestureStartCenter = _center;
                      _gestureStartFocalPoint = details.focalPoint;
                      _gestureStartWidthFraction = _widthFraction;
                    },
                    onScaleUpdate: (details) {
                      final delta =
                          details.focalPoint - _gestureStartFocalPoint;
                      final newWidthFraction =
                          (_gestureStartWidthFraction * details.scale).clamp(
                            0.1,
                            0.95,
                          );
                      final candidateCenter = Offset(
                        _gestureStartCenter.dx + delta.dx / canvasSize.width,
                        _gestureStartCenter.dy + delta.dy / canvasSize.height,
                      );
                      setState(() {
                        _widthFraction = newWidthFraction;
                        _center = _clampCenter(candidateCenter, canvasSize);
                      });
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: RawImage(image: overlayImage, fit: BoxFit.fill),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Size _fitSize(Size source, Size available) {
    final sourceAspect = source.width / source.height;
    final availableAspect = available.width / available.height;
    if (sourceAspect > availableAspect) {
      return Size(available.width, available.width / sourceAspect);
    }
    return Size(available.height * sourceAspect, available.height);
  }

  Size _overlaySize(Size canvasSize) {
    final overlay = _overlayImage!;
    final width = canvasSize.width * _widthFraction;
    return Size(width, width * overlay.height / overlay.width);
  }

  Offset _clampCenter(Offset center, Size canvasSize) {
    final overlaySize = _overlaySize(canvasSize);
    final halfWidth = overlaySize.width / canvasSize.width / 2;
    final halfHeight = overlaySize.height / canvasSize.height / 2;
    return Offset(
      center.dx.clamp(halfWidth, 1 - halfWidth),
      center.dy.clamp(halfHeight, 1 - halfHeight),
    );
  }

  Future<void> _save() async {
    final baseImage = _baseImage;
    final overlayImage = _overlayImage;
    if (baseImage == null || overlayImage == null) return;

    setState(() => _isSaving = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final baseSize = Size(
        baseImage.width.toDouble(),
        baseImage.height.toDouble(),
      );
      canvas.drawImage(baseImage, Offset.zero, Paint());

      final overlayWidth = baseSize.width * _widthFraction;
      final overlayHeight =
          overlayWidth * overlayImage.height / overlayImage.width;
      final destination = Rect.fromCenter(
        center: Offset(
          _center.dx * baseSize.width,
          _center.dy * baseSize.height,
        ),
        width: overlayWidth,
        height: overlayHeight,
      );
      canvas.drawImageRect(
        overlayImage,
        Rect.fromLTWH(
          0,
          0,
          overlayImage.width.toDouble(),
          overlayImage.height.toDouble(),
        ),
        destination,
        Paint()..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();
      final outputImage = await picture.toImage(
        baseImage.width,
        baseImage.height,
      );
      picture.dispose();
      final byteData = await outputImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      outputImage.dispose();
      if (byteData == null) throw StateError('Could not encode image');

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/image_overlay_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(Uint8List.view(byteData.buffer), flush: true);
      if (mounted) Navigator.pop(context, file.path);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add that image')),
        );
      }
    }
  }
}
