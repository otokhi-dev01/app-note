import 'package:flutter/material.dart';
import 'package:notes/app/theme/colors.dart';

class HomeStyle {
  const HomeStyle({required this.theme, required this.isDark});

  factory HomeStyle.of(BuildContext context) {
    final theme = Theme.of(context);

    return HomeStyle(theme: theme, isDark: theme.brightness == Brightness.dark);
  }

  final ThemeData theme;
  final bool isDark;

  static const magenta = AppColors.magenta;
  static const primary = AppColors.primary;
  static const orange = AppColors.primary;
  static const yellow = AppColors.yellow;
  static const red = AppColors.red;
  static const blue = AppColors.primary;

  Color adaptive({required Color light, required Color dark}) {
    return isDark ? dark : light;
  }

  Color get background =>
      adaptive(light: AppColors.background, dark: const Color(0xFF111113));

  Color get surface => adaptive(
    light: AppColors.surface,
    dark: const Color(0xFF1C1C1E), // iOS Secondary System Background
  );

  Color get secondarySurface => adaptive(
    light: AppColors.surfaceVariant,
    dark: const Color(0xFF2C2C2E), // iOS Tertiary System Background
  );

  Color get primaryText => adaptive(light: Colors.black, dark: Colors.white);

  Color get secondaryText => adaptive(
    light: const Color(0xFF3C3C43).withValues(alpha: 0.6),
    dark: const Color(0xFFEBEBF5).withValues(alpha: 0.6),
  );

  Color get border =>
      adaptive(light: const Color(0xFFC6C6C8), dark: const Color(0xFF38383A));

  Color get shadow => Colors.black.withValues(alpha: isDark ? 0.3 : 0.08);

  Color get errorBackground => adaptive(
    light: HomeStyle.red.withValues(alpha: 0.05),
    dark: HomeStyle.red.withValues(alpha: 0.12),
  );

  Color get placeholder =>
      adaptive(light: const Color(0xFFE5E5EA), dark: const Color(0xFF3A3A3C));
}
