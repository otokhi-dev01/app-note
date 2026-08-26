import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/storage/settings_preferences.dart';

class AppSnackbar {
  AppSnackbar._();

  static const Duration _short = Duration(milliseconds: 1600);
  static const Duration _long = Duration(seconds: 3);

  static void success(String title, [String message = '']) {
    if (!_actionConfirmationsEnabled) return;
    _show(
      title: title,
      message: message,
      accent: const Color(0xFF34C759),
      icon: Icons.check_circle_outline,
      duration: _short,
    );
  }

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

  static bool get _actionConfirmationsEnabled {
    if (!Get.isRegistered<SettingsPreferences>()) return true;
    return Get.find<SettingsPreferences>().actionConfirmations.value;
  }

  static void _show({
    required String title,
    required String message,
    required Color accent,
    required IconData icon,
    required Duration duration,
  }) {
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
