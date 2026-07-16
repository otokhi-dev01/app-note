import 'package:flutter/material.dart';
import 'package:notes/app/theme/app_colors.dart';

BoxDecoration libraryCardDecoration(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: colors.outlineVariant),
    boxShadow: [
      BoxShadow(
        color: colors.shadow.withValues(alpha: .07),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

const libraryFeatureEyebrow = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 12,
  letterSpacing: 1.2,
  fontWeight: FontWeight.w700,
);
