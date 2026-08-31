import 'dart:io';

import 'package:flutter/services.dart';

/// App-owned native media features.
///
/// Keeping these small platform integrations in the application avoids
/// depending on CocoaPods-only Flutter plugins on iOS.
abstract final class NativeMediaServices {
  static const _channel = MethodChannel('com.kimchheang.otokhi-note/media');

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
