import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

export 'package:Note/shared/widgets/glass_inputs.dart';
export 'package:Note/shared/widgets/glass_surfaces.dart';

/// Shapes supported by the app's reusable liquid-glass widgets.
enum GlassShape { roundedRectangle, oval, circle }

/// A reusable, standalone liquid-glass surface.
///
/// This app-level wrapper keeps package-specific setup in one place while
/// still exposing the options commonly needed by feature widgets.
class CustomGlassContainer extends StatelessWidget {
  final Widget? child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final double thickness;
  final double refractiveIndex;
  final double chromaticAberration;

  /// The lighting direction in degrees.
  final double lightAngle;

  final double glowIntensity;
  final bool showGlow;
  final bool animateLiquid;
  final GlassShape shape;
  final Color? glassColor;
  final bool useOwnLayer;
  final lg.GlassQuality? quality;
  final Clip clipBehavior;
  final bool allowElevation;
  final bool platformViewBackdrop;

  const CustomGlassContainer({
    super.key,
    this.child,
    this.blur = 20,
    this.opacity = 0.8,
    this.borderRadius = 30,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.thickness = 10,
    this.refractiveIndex = 1.2,
    this.chromaticAberration = 0.05,
    this.lightAngle = 45,
    this.glowIntensity = 0,
    this.showGlow = false,
    this.animateLiquid = false,
    this.shape = GlassShape.roundedRectangle,
    this.glassColor,
    this.useOwnLayer = true,
    this.quality,
    this.clipBehavior = Clip.none,
    this.allowElevation = false,
    this.platformViewBackdrop = false,
  }) : assert(blur >= 0),
       assert(borderRadius >= 0),
       assert(width == null || width >= 0),
       assert(height == null || height >= 0),
       assert(thickness >= 0),
       assert(refractiveIndex > 0),
       assert(chromaticAberration >= 0),
       assert(glowIntensity >= 0 && glowIntensity <= 1);

  @override
  Widget build(BuildContext context) {
    return lg.GlassContainer(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      alignment: alignment,
      shape: _packageShape(shape, borderRadius),
      settings: _settingsFor(
        context,
        blur: blur,
        opacity: opacity,
        thickness: thickness,
        refractiveIndex: refractiveIndex,
        chromaticAberration: chromaticAberration,
        lightAngle: lightAngle,
        glassColor: glassColor,
        glowIntensity: showGlow ? math.max(glowIntensity, 0.75) : glowIntensity,
      ),
      useOwnLayer: useOwnLayer,
      quality: quality,
      clipBehavior: clipBehavior,
      allowElevation: allowElevation,
      glowIntensity: showGlow ? math.max(glowIntensity, 0.75) : glowIntensity,
      platformViewBackdrop: platformViewBackdrop,
      child: child,
    );
  }
}

/// A reusable button rendered by [lg.GlassButton].
///
/// Set [onPressed] to null to show the package's disabled state. The child can
/// be text, an icon, or any custom layout.
class CustomGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double? width;
  final double? height;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final GlassShape shape;
  final double borderRadius;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final double blur;
  final double opacity;
  final double thickness;
  final double refractiveIndex;
  final double chromaticAberration;

  /// The lighting direction in degrees.
  final double lightAngle;

  final Color? glassColor;
  final Color? glowColor;
  final double glowIntensity;
  final bool useOwnLayer;
  final lg.GlassQuality? quality;
  final lg.GlassButtonStyle style;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool anchorStretch;
  final bool platformViewBackdrop;

  const CustomGlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel = '',
    this.width,
    this.height,
    this.minHeight = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.alignment = Alignment.center,
    this.shape = GlassShape.roundedRectangle,
    this.borderRadius = 18,
    this.foregroundColor,
    this.textStyle,
    this.blur = 20,
    this.opacity = 0.2,
    this.thickness = 10,
    this.refractiveIndex = 1.2,
    this.chromaticAberration = 0.05,
    this.lightAngle = 45,
    this.glassColor,
    this.glowColor,
    this.glowIntensity = 0.75,
    this.useOwnLayer = true,
    this.quality,
    this.style = lg.GlassButtonStyle.filled,
    this.focusNode,
    this.autofocus = false,
    this.anchorStretch = true,
    this.platformViewBackdrop = false,
  }) : assert(width == null || width >= 0),
       assert(height == null || height >= 0),
       assert(minHeight >= 0),
       assert(borderRadius >= 0),
       assert(blur >= 0),
       assert(thickness >= 0),
       assert(refractiveIndex > 0),
       assert(chromaticAberration >= 0),
       assert(glowIntensity >= 0 && glowIntensity <= 1);

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    final defaultTextStyle = Theme.of(context).textTheme.labelLarge;
    final buttonContent = Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: IconTheme.merge(
          data: IconThemeData(color: color),
          child: DefaultTextStyle.merge(
            style:
                defaultTextStyle?.copyWith(color: color).merge(textStyle) ??
                TextStyle(color: color).merge(textStyle),
            child: child,
          ),
        ),
      ),
    );
    final content = height == null
        ? ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: buttonContent,
          )
        : buttonContent;

    return lg.GlassButton.custom(
      onTap: onPressed ?? _noOp,
      enabled: onPressed != null,
      label: semanticLabel,
      width: width,
      height: height,
      shape: _packageShape(shape, borderRadius),
      settings: _settingsFor(
        context,
        blur: blur,
        opacity: opacity,
        thickness: thickness,
        refractiveIndex: refractiveIndex,
        chromaticAberration: chromaticAberration,
        lightAngle: lightAngle,
        glassColor: glassColor,
        glowIntensity: glowIntensity,
      ),
      useOwnLayer: useOwnLayer,
      quality: quality,
      glowColor: glowColor,
      glowOpacity: glowIntensity,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      anchorStretch: anchorStretch,
      alignment: alignment,
      platformViewBackdrop: platformViewBackdrop,
      child: content,
    );
  }
}

/// A ready-to-use liquid-glass ellipsis button for overflow menus.
class MoreButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final String semanticLabel;
  final bool useOwnLayer;
  final lg.GlassQuality? quality;

  const MoreButton({
    super.key,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 24,
    this.iconColor,
    this.semanticLabel = 'More options',
    this.useOwnLayer = true,
    this.quality,
  }) : assert(size >= 0),
       assert(iconSize >= 0);

  @override
  Widget build(BuildContext context) {
    return CustomGlassButton(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      shape: GlassShape.circle,
      foregroundColor: iconColor,
      blur: 10,
      opacity: 0.15,
      thickness: 8,
      useOwnLayer: useOwnLayer,
      quality: quality,
      child: Icon(Icons.more_horiz, size: iconSize),
    );
  }
}

/// Backwards-compatible name used by the existing screens.
///
/// New code can use [CustomGlassContainer] directly.
class LiquidGlassContainer extends CustomGlassContainer {
  final bool useFakeGlass;
  final BoxBorder? border;

  const LiquidGlassContainer({
    super.key,
    required Widget child,
    super.blur = 20,
    super.opacity = 0.8,
    super.borderRadius = 30,
    super.padding,
    super.width,
    super.height,
    super.thickness = 10,
    super.refractiveIndex = 1.2,
    super.chromaticAberration = 0.05,
    super.lightAngle = 45,
    this.useFakeGlass = false,
    super.showGlow = false,
    super.shape = GlassShape.roundedRectangle,
    this.border,
    super.animateLiquid = false,
  }) : super(child: child, useOwnLayer: true);
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
    this.thickness = 10,
    this.refractiveIndex = 1.2,
    this.opacity = 0.1,
    this.blur = 35,
    this.animateLiquid = false,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomGlassContainer(
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
      opacity: opacity,
      blur: blur,
      thickness: thickness,
      refractiveIndex: refractiveIndex,
      glowIntensity: showGlow ? 0.75 : 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...children, const SizedBox(height: 4)],
      ),
    );
  }
}

lg.LiquidShape _packageShape(GlassShape shape, double borderRadius) {
  return switch (shape) {
    GlassShape.circle || GlassShape.oval => const lg.LiquidOval(),
    GlassShape.roundedRectangle => lg.LiquidRoundedSuperellipse(
      borderRadius: borderRadius,
    ),
  };
}

lg.LiquidGlassSettings _settingsFor(
  BuildContext context, {
  required double blur,
  required double opacity,
  required double thickness,
  required double refractiveIndex,
  required double chromaticAberration,
  required double lightAngle,
  required Color? glassColor,
  required double glowIntensity,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final normalizedOpacity = _clampUnit(opacity);
  final defaultOpacity = isDark
      ? math.min(normalizedOpacity, 0.1)
      : normalizedOpacity;

  return lg.LiquidGlassSettings(
    blur: blur,
    thickness: thickness,
    refractiveIndex: refractiveIndex,
    chromaticAberration: chromaticAberration,
    lightAngle: lightAngle * (math.pi / 180),
    glassColor: glassColor ?? Colors.white.withValues(alpha: defaultOpacity),
    glowIntensity: glowIntensity,
  );
}

double _clampUnit(double value) {
  if (value.isNaN) return 0;
  return value.clamp(0.0, 1.0).toDouble();
}

void _noOp() {}
