import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UIHelpers {
  static void showSnackBar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
      colorText: isError ? Colors.red : Colors.green,
      margin: const EdgeInsets.all(20),
    );
  }

  static Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(cancelText)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(confirmText)),
        ],
      ),
    );
  }
}
