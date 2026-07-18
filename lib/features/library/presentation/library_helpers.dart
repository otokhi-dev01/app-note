import 'package:flutter/material.dart';

BoxDecoration libraryCardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colors.surface.withValues(
      alpha: theme.brightness == Brightness.dark ? .90 : .94,
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: colors.outlineVariant.withValues(
        alpha: theme.brightness == Brightness.dark ? .48 : .36,
      ),
    ),
    boxShadow: theme.brightness == Brightness.dark
        ? const []
        : [
            BoxShadow(
              color: colors.shadow.withValues(alpha: .045),
              blurRadius: 28,
              spreadRadius: -8,
              offset: const Offset(0, 12),
            ),
          ],
  );
}

TextStyle libraryFeatureEyebrow(BuildContext context) {
  return TextStyle(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    fontSize: 13,
    letterSpacing: .05,
    fontWeight: FontWeight.w600,
  );
}
