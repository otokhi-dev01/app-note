import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand color sampled from assets/icons/notes.jpg.
  static const primary = Color(0xFFEC00B5);
  static const magenta = primary; // Kept for backwards-compatible call sites.
  static const orange = primary;
  static const red = Color(0xFFC62828);
  static const yellow = Color(0xFFFF64D7);

  // Neutral Colors
  static const background = Color(0xFFFFF8FD);
  static const surface = Color(0xFFFFFBFE);
  static const surfaceVariant = Color(0xFFF7EAF3);
  static const outline = Color(0xFFD9C5D2);
  static const danger = Color(0xFFFF453A);

  // Text Colors
  static const textPrimary = Color(0xFF191A1E);
  static const textSecondary = Color(0xFF8B7485);
  static const subtitle = Color(0xFF8B7485);
}
