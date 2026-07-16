import 'package:flutter/material.dart';
import 'package:notes/app/theme/app_colors.dart';

@immutable
final class SettingsPalette {
  const SettingsPalette._({required this.isDark});

  factory SettingsPalette.of(BuildContext context) {
    return SettingsPalette._(
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
  }

  final bool isDark;

  Color get background =>
      isDark ? const Color(0xFF111113) : AppColors.background;

  Color get surface => isDark ? const Color(0xFF1C1C1E) : AppColors.surface;

  Color get primaryText => isDark ? Colors.white : Colors.black;

  Color get secondaryText => isDark
      ? const Color(0xFFEBEBF5).withValues(alpha: 0.6)
      : const Color(0xFF3C3C43).withValues(alpha: 0.6);

  Color get border =>
      isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8);
}
