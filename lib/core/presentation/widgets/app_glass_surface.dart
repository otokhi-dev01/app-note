import 'dart:ui';
import 'package:flutter/material.dart';

class AppGlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tintColor;
  final Color? borderColor;
  final double blur;

  const AppGlassSurface({
    required this.child,
    this.borderRadius = 28,
    this.padding,
    this.tintColor,
    this.borderColor,
    this.blur = 28,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.shadow.withValues(alpha: isDark ? 0.12 : 0.05),
              blurRadius: 32,
              spreadRadius: -8,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: tintColor ??
                    colors.surface.withValues(alpha: isDark ? 0.72 : 0.64),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor ??
                      colors.outlineVariant.withValues(
                        alpha: isDark ? 0.45 : 0.55,
                      ),
                  width: 1.2,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
