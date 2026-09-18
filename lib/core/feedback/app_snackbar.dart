import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:Note/core/error/failures.dart';

class AppSnackbar {
  AppSnackbar._();

  /// Lives above the navigator, so notifications survive route replacement
  /// without a separate GetX overlay owning a manually disposed focus scope.
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static const Duration _short = Duration(milliseconds: 1600);
  static const Duration _long = Duration(seconds: 3);

  static void success(String title, [String message = '']) => _show(
    title: title,
    message: message,
    accent: const Color(0xFF34C759),
    icon: Icons.check_circle_outline,
    duration: _short,
  );

  static void info(String title, [String message = '']) => _show(
    title: title,
    message: message,
    accent: const Color(0xFF32ADE6),
    icon: Icons.info_outline,
    duration: _short,
  );

  static void warning(String title, [String message = '']) => _show(
    title: title,
    message: message,
    accent: const Color(0xFFFF9500),
    icon: Icons.warning_amber_outlined,
    duration: _long,
  );

  static void error(String title, [String message = '']) => _show(
    title: title,
    message: message,
    accent: const Color(0xFFFF3B30),
    icon: Icons.error_outline,
    duration: _long,
  );

  static void failure(String title, AppFailure failure) => switch (failure) {
    NetworkFailure() => warning(title, failure.message),
    UnsupportedFeatureFailure() => info(title, failure.message),
    ValidationFailure() => warning(title, failure.message),
    _ => error(title, failure.message),
  };

  static void _show({
    required String title,
    required String message,
    required Color accent,
    required IconData icon,
    required Duration duration,
  }) {
    void show() {
      final context = Get.context;
      final messenger =
          messengerKey.currentState ??
          (context != null && context.mounted
              ? ScaffoldMessenger.maybeOf(context)
              : null);
      if (messenger == null || !messenger.mounted) return;
      final surface = Theme.of(messenger.context).colorScheme.surface;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Color.alphaBlend(accent.withValues(alpha: 0.14), surface),
          content: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(message, style: TextStyle(color: accent)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Resolve the messenger when the callback runs; never retain a route's
    // BuildContext across asynchronous navigation or disposal.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => show());
    } else {
      show();
    }
  }
}
