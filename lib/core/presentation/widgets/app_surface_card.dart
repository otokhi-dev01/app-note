import 'package:flutter/material.dart';

/// The standard elevated surface used for content cards throughout the app.
class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    required this.child,
    required this.padding,
    this.borderRadius = 18,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D22) : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.18 : 0.35),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  spreadRadius: -8,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}
