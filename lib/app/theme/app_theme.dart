import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryDark : AppColors.primary;
    final onAccent = isDark ? const Color(0xFF2B001F) : Colors.white;
    final danger = isDark ? AppColors.redDark : AppColors.danger;
    final background = isDark ? const Color(0xFF090709) : AppColors.background;
    final surface = isDark ? const Color(0xFF211C20) : AppColors.surface;
    final surfaceContainer = isDark
        ? const Color(0xFF302930)
        : AppColors.surfaceVariant;
    final onSurface = isDark ? const Color(0xFFFFF7FC) : AppColors.textPrimary;
    final secondaryText = isDark
        ? const Color(0xFFD0C4CC)
        : AppColors.textSecondary;
    final separator = isDark ? const Color(0xFF4C414A) : AppColors.outline;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: onAccent,
          primaryContainer: isDark
              ? const Color(0xFF5A0849)
              : const Color(0xFFFFD9F2),
          onPrimaryContainer: isDark
              ? const Color(0xFFFFD8F1)
              : const Color(0xFF3D002D),
          secondary: isDark ? const Color(0xFFBDAAFF) : AppColors.blue,
          onSecondary: isDark ? const Color(0xFF26134E) : Colors.white,
          tertiary: isDark ? const Color(0xFFFFA8DC) : const Color(0xFFB61B7E),
          error: danger,
          onError: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          surface: surface,
          onSurface: onSurface,
          onSurfaceVariant: secondaryText,
          surfaceContainerLowest: isDark
              ? const Color(0xFF100D10)
              : Colors.white,
          surfaceContainerLow: isDark
              ? const Color(0xFF191519)
              : const Color(0xFFFCF8FB),
          surfaceContainer: surfaceContainer,
          surfaceContainerHigh: isDark
              ? const Color(0xFF393139)
              : const Color(0xFFECE3EA),
          surfaceContainerHighest: isDark
              ? const Color(0xFF443A42)
              : const Color(0xFFE3D8E1),
          outline: isDark ? const Color(0xFF776A74) : const Color(0xFFAFA2AC),
          outlineVariant: separator,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashColor: accent.withValues(alpha: .12),
      highlightColor: accent.withValues(alpha: .06),
      focusColor: accent.withValues(alpha: .12),
      dividerColor: separator,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: accent,
        primaryContrastingColor: onAccent,
        scaffoldBackgroundColor: background,
        barBackgroundColor: Colors.transparent,
        textTheme: CupertinoTextThemeData(
          primaryColor: onSurface,
          textStyle: TextStyle(
            color: onSurface,
            fontSize: 17,
            letterSpacing: -.2,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: onSurface,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: accent),
        actionsIconTheme: IconThemeData(color: accent),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: secondaryText.withValues(alpha: .45),
        dragHandleSize: const Size(36, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        elevation: 0,
        backgroundColor: surface.withValues(alpha: .78),
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: .17),
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? accent
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? accent
                : scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: accent,
        textColor: onSurface,
        subtitleTextStyle: TextStyle(color: secondaryText, fontSize: 14),
        minTileHeight: 52,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: TextStyle(color: secondaryText, fontSize: 16),
        labelStyle: TextStyle(color: secondaryText),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: surfaceContainer,
          disabledForegroundColor: secondaryText,
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(48, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          backgroundColor: surface,
          minimumSize: const Size(48, 50),
          side: BorderSide(color: separator),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
        elevation: 5,
        focusElevation: 5,
        hoverElevation: 7,
        highlightElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: accent.withValues(alpha: .16),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFFE5E5EA)
            : const Color(0xFF2C2C2E),
        contentTextStyle: TextStyle(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? onAccent : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          color: scheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -.7,
        ),
        titleLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -.45,
        ),
        titleMedium: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -.25,
        ),
        bodyLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 17,
          height: 1.45,
          letterSpacing: -.2,
        ),
        bodyMedium: TextStyle(
          color: scheme.onSurface,
          fontSize: 15,
          height: 1.4,
          letterSpacing: -.1,
        ),
        bodySmall: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      ),
    );
  }
}
