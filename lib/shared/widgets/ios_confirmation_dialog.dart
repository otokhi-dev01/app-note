import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class IOSConfirmationDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const IOSConfirmationDialog({
    super.key,
    required this.title,
    this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.isDestructive = true,
  });

  /// Shows the dialog and completes once it is dismissed, so callers can
  /// `await` it and act on the outcome.
  static Future<void> show({
    required String title,
    String? message,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool isDestructive = true,
  }) {
    return Get.dialog(
      IOSConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        isDestructive: isDestructive,
      ),
      barrierColor: Colors.black.withValues(alpha: 0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomGlassDialog(
      title: title,
      message: message,
      actions: [
        CustomGlassDialogAction(label: 'Cancel', onPressed: () => Get.back()),
        CustomGlassDialogAction(
          label: confirmLabel,
          onPressed: onConfirm,
          isPrimary: !isDestructive,
          isDestructive: isDestructive,
        ),
      ],
    );
  }
}
