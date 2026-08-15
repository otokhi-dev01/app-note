import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

// Unique Version: 2026-08-15-09-30
enum GlassShape { roundedRectangle, oval, circle }

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  final double thickness;
  final double refractiveIndex;
  final double chromaticAberration;
  final double lightAngle;
  final bool useFakeGlass;
  final bool showGlow;
  final GlassShape shape;
  final BoxBorder? border;
  final bool animateLiquid;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.8,
    this.borderRadius = 30,
    this.padding,
    this.width,
    this.height,
    this.thickness = 10.0,
    this.refractiveIndex = 1.2,
    this.chromaticAberration = 0.05,
    this.lightAngle = 45.0,
    this.useFakeGlass = false,
    this.showGlow = false,
    this.shape = GlassShape.roundedRectangle,
    this.border,
    this.animateLiquid = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Convert GlassShape to package's LiquidShape
    lg.LiquidShape packageShape;
    switch (shape) {
      case GlassShape.circle:
        packageShape = const lg.LiquidOval();
        break;
      case GlassShape.oval:
        packageShape = const lg.LiquidOval();
        break;
      case GlassShape.roundedRectangle:
        packageShape = lg.LiquidRoundedSuperellipse(borderRadius: borderRadius);
        break;
    }

    final settings = lg.LiquidGlassSettings(
      blur: blur,
      thickness: thickness,
      refractiveIndex: refractiveIndex,
      chromaticAberration: chromaticAberration,
      lightAngle: lightAngle * (math.pi / 180),
      glassColor: isDark 
          ? Colors.white.withValues(alpha: 0.1) 
          : Colors.white.withValues(alpha: opacity),
      glowIntensity: showGlow ? 0.75 : 0.0,
    );

    return lg.GlassContainer(
      width: width,
      height: height,
      padding: padding,
      shape: packageShape,
      settings: settings,
      useOwnLayer: true, // Legacy compatibility: old one always had its own layer logic
      child: child,
    );
  }
}

class GlassCard extends StatelessWidget {
  final List<Widget> children;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double thickness;
  final double refractiveIndex;
  final double opacity;
  final double blur;
  final bool animateLiquid;
  final bool showGlow;

  const GlassCard({
    super.key,
    required this.children,
    this.borderRadius = 30,
    this.padding,
    this.thickness = 10.0,
    this.refractiveIndex = 1.2,
    this.opacity = 0.1,
    this.blur = 35,
    this.animateLiquid = false,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
      opacity: opacity,
      blur: blur,
      thickness: thickness,
      refractiveIndex: refractiveIndex,
      animateLiquid: animateLiquid,
      showGlow: showGlow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
