import 'dart:ui';
import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.blur = 22,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark = theme.brightness == Brightness.dark;

    final Color glassColor = isDark
        ? const Color(0xFF1B1D22).withValues(alpha: 0.74)
        : Colors.white.withValues(alpha: 0.72);

    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.80);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.07),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
