part of '../home_controller.dart';

extension _HomeFeedback on HomeController {
  void _showStatusSnackbar(
    String title,
    String message, {
    bool isDestructive = false,
  }) {
    final scheme = Get.theme.colorScheme;
    final background = isDestructive ? scheme.error : scheme.secondary;
    final foreground = isDestructive ? scheme.onError : scheme.onSecondary;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: background,
      colorText: foreground,
      borderRadius: 15,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 2),
      icon: Icon(
        isDestructive
            ? CupertinoIcons.trash_fill
            : CupertinoIcons.info_circle_fill,
        color: foreground,
      ),
    );
  }

  void _showNoteError(String title, Object error) {
    _showStatusSnackbar(title, _readableError(error), isDestructive: true);
  }

  String _readableError(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) return 'Please try again.';
    return message
        .replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '')
        .trim();
  }
}
