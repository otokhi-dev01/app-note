import 'dart:io';

import 'package:flutter/services.dart';

/// App-owned native media features.
///
/// Keeping these small platform integrations in the application avoids
/// depending on CocoaPods-only Flutter plugins on iOS.
abstract final class NativeMediaServices {
  static const _channel = MethodChannel('com.kimchheang.otokhi-note/media');

  /// Returns the new photo's identifier only after the library confirms saving.
  static Future<String> savePhoto(Uint8List bytes, String fileName) async {
    final identifier = await _channel.invokeMethod<String>('savePhoto', {
      'bytes': bytes,
      'fileName': fileName,
    });
    if (identifier == null || identifier.isEmpty) {
      throw PlatformException(code: 'PHOTO_SAVE_FAILED');
    }
    return identifier;
  }

  static Future<String> recognizeText(String imagePath) async {
    return await _channel.invokeMethod<String>('recognizeText', {
          'path': imagePath,
        }) ??
        '';
  }

  static Future<String?> editImage(String imagePath) {
    if (!Platform.isIOS) return Future.value();
    return _channel.invokeMethod<String>('editImage', {'path': imagePath});
  }

  static Future<String?> editPdf(String pdfPath) {
    if (!Platform.isIOS) return Future.value();
    return _channel.invokeMethod<String>('editPdf', {'path': pdfPath});
  }
}
