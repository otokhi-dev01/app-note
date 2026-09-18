import 'package:flutter/services.dart';

abstract final class IdentityOcr {
  static const channel = MethodChannel('com.piisiit/identity_ocr');

  static Future<String> recognize(
          String imagePath, String modelDirectory) async =>
      await channel.invokeMethod<String>('recognize', {
        'path': imagePath,
        'dataPath': modelDirectory,
      }) ??
      '';
}
