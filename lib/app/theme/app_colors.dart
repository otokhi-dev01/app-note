import 'package:flutter/material.dart';

abstract final class AppColors {
  // A warm system orange gives the app the familiar Notes character without
  // relying on platform-specific private colours.
  // The light-mode tint is dark enough for text and controls on white cards.
  // Dark mode uses [primaryDark] for the brighter system-orange appearance.
  static const primary = Color(0xFFAD5500);
  static const primaryDark = Color(0xFFFF9F0A);
  static const orange = primary;
  static const yellow = Color(0xFFFFD60A);
  static const blue = Color(0xFF0A84FF);
  static const indigo = Color(0xFF5E5CE6);
  static const green = Color(0xFF30D158);
  static const red = Color(0xFFC9342C);
  static const redDark = Color(0xFFFF453A);

  // Neutral Colors
  static const background = Color(0xFFF2F2F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFE9E9EF);
  static const outline = Color(0xFFD1D1D6);
  static const danger = red;

  // Text Colors
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF6C6C70);
  static const subtitle = textSecondary;
}
