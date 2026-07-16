import 'package:flutter/material.dart';

BoxDecoration libraryCardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: colors.outlineVariant.withValues(
        alpha: theme.brightness == Brightness.dark ? .42 : .28,
      ),
    ),
    boxShadow: theme.brightness == Brightness.dark
        ? const []
        : [
            BoxShadow(
              color: colors.shadow.withValues(alpha: .045),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
  );
}

TextStyle libraryFeatureEyebrow(BuildContext context) {
  return TextStyle(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    fontSize: 12,
    letterSpacing: .7,
    fontWeight: FontWeight.w700,
  );
}
