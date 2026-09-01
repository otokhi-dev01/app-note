import 'dart:async';

import 'package:flutter/services.dart';

class IOSImageEditor {
  static const MethodChannel _channel = MethodChannel('ios_image_editor');

  /// Opens the native iOS markup editor.
  static Future<String?> editImage(String path) {
    return _channel.invokeMethod<String>('editImage', {'path': path});
  }
}
