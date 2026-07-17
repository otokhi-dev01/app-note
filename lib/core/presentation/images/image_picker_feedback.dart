import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

abstract final class ImagePickerFeedback {
  static Future<bool> show(
    PlatformException error, {
    required ImageSource source,
  }) async {
    final denied = _isAccessDenied(error.code);
    final isCamera = source == ImageSource.camera;
    final sourceName = isCamera ? 'Camera' : 'Photo Library';
    final title = denied
        ? '$sourceName access needed'
        : 'Unable to open $sourceName';
    final message = denied
        ? isCamera
              ? 'Camera access is turned off. Allow camera access for Notes in Settings, or choose a photo from your library.'
              : 'Photo Library access is turned off. Allow photo access for Notes in Settings, then try again.'
        : 'The $sourceName could not be opened. Please try again.';

    return await Get.dialog<bool>(
          CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Get.back(result: false),
                child: Text(isCamera && denied ? 'Cancel' : 'OK'),
              ),
              if (isCamera && denied)
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Get.back(result: true),
                  child: const Text('Choose Photo'),
                ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }

  static bool _isAccessDenied(String code) {
    final normalized = code.toLowerCase();
    return normalized.contains('access_denied') ||
        normalized.contains('access_restricted') ||
        normalized.contains('permission_denied');
  }
}
