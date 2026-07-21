import 'package:flutter/material.dart';

Color parseFolderColor(String rawValue, Color fallback) {
  final String value = rawValue.trim();

  if (value.isEmpty || value.toLowerCase() == 'string') {
    return fallback;
  }

  try {
    String hex = value.replaceAll('#', '').replaceAll('0x', '');

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return fallback;
    }

    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return fallback;
  }
}
