import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // LIGHT MODE COLORS
  static const Color bodyColor = Color(0xFFF2F2F7);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF3C3C43);
  static const Color textGrey = Color(0xFF8E8E93);

  // Alias for Note branding compatibility
  static const Color folderPink = Color(0xFFFF69B4);
  static const Color folderYellow = folderPink;
  static const Color dividerColor = Color(0xFFE5E5EA);
  static const Color searchBarColor = Color(0xFFFFFFFF);
  static const Color hintColor = Color(0xFF8E8E93);

  // DARK MODE COLORS
  static const Color darkBackground = Color(0xFF000000);
  // iOS-style dark card / surface
  static const Color darkCardColor = Color(0xFF1C1C1E);
  // iOS Notes yellow (Renamed to Pink)
  static const Color darkFolderPink = Color(0xFFFF1493);
  static const Color darkFolderYellow = darkFolderPink;
  // Alias for  branding compatibility
  // Primary text
  static const Color darkTextPrimary = Color(0xFFF2F2F7);
  // Secondary text
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  // Divider
  static const Color darkDividerColor = Color(0xFF38383A);
  // Search bar
  static const Color darkSearchBarColor = Color(0xFF1C1C1E);

  // LIGHT THEME
  static final light = ThemeData(
    brightness: Brightness.light,
    primaryColor: folderPink,
    scaffoldBackgroundColor: bodyColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: folderPink,
      primary: folderPink,
      surface: cardColor,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
    ),
    dividerTheme: const DividerThemeData(color: dividerColor, thickness: 0.5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: folderPink),
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      bodyLarge: const TextStyle(color: textPrimary),
      bodyMedium: const TextStyle(color: textSecondary),
    ),
    useMaterial3: true,
  );

  // DARK THEME
  static final dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    primaryColor: darkFolderPink,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      // Main accent
      primary: darkFolderPink,
      onPrimary: Colors.black,
      // Secondary accent
      secondary: darkFolderPink,
      onSecondary: Colors.black,
      // Background
      surface: darkCardColor,
      onSurface: darkTextPrimary,
      // Material 3 surfaces
      surfaceContainer: darkCardColor,
      surfaceContainerHighest: darkCardColor,
      // Secondary text / icons
      onSurfaceVariant: darkTextSecondary,
      // Borders / dividers
      outline: darkDividerColor,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: darkDividerColor,
      thickness: 0.5,
      space: 0,
    ),

    // ------------------------------------------------------------
    // AppBar
    // ------------------------------------------------------------
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: darkFolderPink, size: 24),
    ),

    // ------------------------------------------------------------
    // Text
    // ------------------------------------------------------------
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          bodyLarge: const TextStyle(color: darkTextPrimary, fontSize: 17),

          bodyMedium: const TextStyle(color: darkTextSecondary, fontSize: 15),

          bodySmall: const TextStyle(color: darkTextSecondary, fontSize: 13),

          titleLarge: const TextStyle(
            color: darkTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),

          titleMedium: const TextStyle(
            color: darkTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),

          headlineLarge: const TextStyle(
            color: darkTextPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),

          headlineMedium: const TextStyle(
            color: darkTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
    // Icon
    iconTheme: const IconThemeData(color: darkFolderPink),

    // ------------------------------------------------------------
    // Search / TextField
    // ------------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,

      fillColor: darkSearchBarColor,

      hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 17),

      prefixIconColor: darkTextSecondary,

      suffixIconColor: darkTextSecondary,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ------------------------------------------------------------
    // Card
    // ------------------------------------------------------------
    cardTheme: const CardThemeData(
      color: darkCardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
    ),

    // ------------------------------------------------------------
    // Bottom Sheet
    // ------------------------------------------------------------
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkCardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),

    // ------------------------------------------------------------
    // Dialog
    // ------------------------------------------------------------
    dialogTheme: const DialogThemeData(
      backgroundColor: darkCardColor,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
