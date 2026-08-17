import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/failures.dart';

/// Every toast the app shows.
///
/// Replaces 67 hand-rolled `Get.snackbar` calls that each picked their own
/// position, duration and colors — and several of which fired from inside
/// widgets. Raise these from controllers so the UI layer stays declarative.
class AppSnackbar {
  AppSnackbar._();

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

  /// Shows a domain failure with wording matched to its kind, so an offline
  /// blip does not look like a server crash.
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
    // Replace rather than stack: rapid actions (multi-select delete) would
    // otherwise queue a column of near-identical toasts.
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      borderRadius: 14,
      backgroundColor: accent.withValues(alpha: 0.14),
      colorText: accent,
      icon: Icon(icon, color: accent, size: 22),
      shouldIconPulse: false,
      isDismissible: true,
      animationDuration: const Duration(milliseconds: 260),
    );
  }
}
