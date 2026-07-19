import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return _buildTheme(Brightness.light);
  }

  static ThemeData get dark {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(
      Brightness brightness,
      ) {
    final ColorScheme colorScheme =
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
      brightness == Brightness.dark
          ? const Color(0xFF101114)
          : const Color(0xFFF7F8FA),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
            colorScheme.outlineVariant.withValues(
              alpha: brightness == Brightness.dark
                  ? 0.18
                  : 0.35,
            ),
          ),
        ),
      ),
    );
  }
}