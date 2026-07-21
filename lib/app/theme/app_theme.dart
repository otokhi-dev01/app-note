import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF5B7CFA);

  static ThemeData light({String? fontFamily}) {
    return _buildTheme(brightness: Brightness.light, fontFamily: fontFamily);
  }

  static ThemeData dark({String? fontFamily}) {
    return _buildTheme(brightness: Brightness.dark, fontFamily: fontFamily);
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required String? fontFamily,
  }) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F1115)
          : const Color(0xFFF5F7FB),
      dividerColor: colorScheme.outlineVariant.withValues(
        alpha: isDark ? 0.18 : 0.35,
      ),
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.white.withValues(alpha: 0.78),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.22 : 0.38,
            ),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.22 : 0.38,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
