import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:identity_ocr/identity_ocr.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Full-photo OCR runs once per captured side, separately from live Latin MRZ OCR.
abstract final class IdentityPrintedTextService {
  static Future<String>? _models;

  static Future<String> recognize(String path) async {
    final models = await (_models ??= _prepareModels().catchError((
      Object error,
    ) {
      _models = null;
      throw error;
    }));
    final temporary = await (await getTemporaryDirectory()).createTemp(
      'identity_ocr_',
    );
    try {
      // Bake EXIF orientation and bound memory use before passing to native OCR.
      final bytes = await compute(_preparePhoto, path);
      final image = await File(
        '${temporary.path}/document.png',
      ).writeAsBytes(bytes);
      return await IdentityOcr.recognize(image.path, models);
    } finally {
      try {
        await temporary.delete(recursive: true);
      } on FileSystemException {
        /* Best effort. */
      }
    }
  }

  static Future<String> _prepareModels() async {
    final root =
        '${(await getApplicationSupportDirectory()).path}/identity_ocr_v1';
    final directory = await Directory('$root/tessdata').create(recursive: true);
    for (final language in ['khm', 'eng']) {
      final bytes = await rootBundle.load(
        'assets/tessdata/$language.traineddata',
      );
      final file = File('${directory.path}/$language.traineddata');
      if (!file.existsSync() || await file.length() != bytes.lengthInBytes) {
        final pending = File('${file.path}.pending');
        await pending.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true,
        );
        await pending.rename(file.path);
      }
    }
    return root;
  }
}

Uint8List _preparePhoto(String path) {
  final decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) {
    throw const FormatException('Unsupported identity photo');
  }
  var image = img.bakeOrientation(decoded);
  final longest = math.max(image.width, image.height);
  if (longest > 2800) {
    image = img.copyResize(
      image,
      width: (image.width * 2800 / longest).round(),
      height: (image.height * 2800 / longest).round(),
    );
  }
  return img.encodePng(img.grayscale(image));
}
