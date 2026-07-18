import 'package:flutter/material.dart';

abstract final class AppColors {
  // The supplied artwork uses a vivid magenta. Small light-mode controls use a
  // deeper companion tint so white text remains readable.
  static const brandMagenta = Color(0xFFEC00B5);
  static const primary = Color(0xFFA90080);
  static const primaryDark = Color(0xFFFF4DCE);
  static const orange = primary;
  static const yellow = Color(0xFFFFD60A);
  static const blue = Color(0xFF7047EB);
  static const indigo = Color(0xFF7957F6);
  static const green = Color(0xFF30D158);
  static const red = Color(0xFFC9342C);
  static const redDark = Color(0xFFFF453A);

  // Neutral Colors
  static const background = Color(0xFFF8F5F8);
  static const surface = Color(0xFFFFFBFE);
  static const surfaceVariant = Color(0xFFF0E8EF);
  static const outline = Color(0xFFD8CDD6);
  static const danger = red;

  // Text Colors
  static const textPrimary = Color(0xFF211B20);
  static const textSecondary = Color(0xFF70666E);
  static const subtitle = textSecondary;
}
