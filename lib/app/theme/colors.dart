import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand Colors (Updated from Logo)
  static const primary = Color(0xFFED00B5); // Brand Magenta
  static const magenta = Color(0xFFED00B5); // Primary Action Color
  static const orange = Color(0xFFED00B5);  // Replaced iOS Orange with Brand Color
  static const red = Color(0xFFFF3B30);     // iOS Red
  static const yellow = Color(0xFFFFCC00);  // iOS Yellow
  
  // Neutral Colors
  static const background = Color(0xFFF2F2F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0F0F5);
  static const outline = Color(0xFFD1D1D6);
  static const danger = Color(0xFFFF453A);
  
  // Text Colors
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF3C3C43);
  static const subtitle = Color(0xFF636366);
}
