import 'package:flutter/material.dart';

class ProfileMenuDividerWidget extends StatelessWidget {
  const ProfileMenuDividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Divider(
      height: 1,
      indent: 66,
      color: colors.outlineVariant.withValues(alpha: isDark ? 0.18 : 0.35),
    );
  }
}
