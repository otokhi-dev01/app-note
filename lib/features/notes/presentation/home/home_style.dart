import 'package:flutter/material.dart';

class HomeStyle {
  const HomeStyle({required this.theme, required this.isDark});

  factory HomeStyle.of(BuildContext context) {
    final theme = Theme.of(context);

    return HomeStyle(theme: theme, isDark: theme.brightness == Brightness.dark);
  }

  final ThemeData theme;
  final bool isDark;

  Color adaptive({required Color light, required Color dark}) {
    return isDark ? dark : light;
  }

  Color get background => theme.scaffoldBackgroundColor;

  Color get surface => theme.colorScheme.surface;

  Color get secondarySurface => theme.colorScheme.surfaceContainer;

  Color get primaryText => theme.colorScheme.onSurface;

  Color get secondaryText => theme.colorScheme.onSurfaceVariant;

  Color get border => theme.colorScheme.outlineVariant;

  Color get shadow => Colors.black.withValues(alpha: isDark ? 0.24 : 0.055);

  Color get errorBackground => adaptive(
    light: theme.colorScheme.error.withValues(alpha: 0.05),
    dark: theme.colorScheme.error.withValues(alpha: 0.12),
  );

  Color get placeholder =>
      adaptive(light: const Color(0xFFE5E5EA), dark: const Color(0xFF3A3A3C));
}
