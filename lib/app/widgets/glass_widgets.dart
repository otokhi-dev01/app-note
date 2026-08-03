import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.8, // Increased for a more "white card" look while keeping glass effect
    this.borderRadius = 30,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: isDark 
                ? null 
                : Border.all(
                    color: AppTheme.dividerColor,
                    width: 0.5,
                  ),
          ),
          child: Material(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1) 
                : AppTheme.cardColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final List<Widget> children;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.children,
    this.borderRadius = 30,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      opacity: 1.0, // Solid white card matching folder style
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
