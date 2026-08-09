import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_theme.dart';

// Unique Version: 2026-08-09-14-35
enum GlassShape { roundedRectangle, oval, circle }

class LiquidGlassContainer extends StatefulWidget {
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
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer> with SingleTickerProviderStateMixin {
  late AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animateLiquid) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 10),
      )..repeat();
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color glassColor = isDark 
        ? Colors.white.withValues(alpha: 0.1) 
        : AppTheme.cardColor.withValues(alpha: widget.opacity);

    Widget buildContent() {
      return Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        decoration: BoxDecoration(
          border: widget.border,
          borderRadius: widget.shape == GlassShape.circle ? null : BorderRadius.circular(widget.borderRadius),
          shape: widget.shape == GlassShape.circle ? BoxShape.circle : BoxShape.rectangle,
        ),
        child: widget.child,
      );
    }

    LiquidShape liquidShape;
    switch (widget.shape) {
      case GlassShape.circle:
        liquidShape = const LiquidOval();
        break;
      case GlassShape.oval:
        liquidShape = const LiquidOval();
        break;
      case GlassShape.roundedRectangle:
        liquidShape = LiquidRoundedRectangle(
          borderRadius: widget.borderRadius,
        );
        break;
    }

    Widget glass(double currentAngle) {
      final settings = LiquidGlassSettings(
        thickness: widget.thickness,
        blur: widget.blur,
        refractiveIndex: widget.refractiveIndex,
        chromaticAberration: widget.chromaticAberration,
        lightAngle: currentAngle * (3.14159 / 180), 
        glassColor: glassColor,
      );

      Widget content = buildContent();
      if (widget.showGlow) {
        content = GlassGlow(
          child: content,
        );
      }

      return LiquidGlass.withOwnLayer(
        fake: widget.useFakeGlass,
        settings: settings,
        shape: liquidShape,
        child: content,
      );
    }

    Widget body = widget.animateLiquid && _controller != null
        ? AnimatedBuilder(
            animation: _controller!,
            builder: (context, child) {
              return glass(widget.lightAngle + (_controller!.value * 360));
            },
          )
        : glass(widget.lightAngle);

    return body;
  }
}

class GlassCard extends StatelessWidget {
  final List<Widget> children;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double thickness;
  final double refractiveIndex;
  final bool animateLiquid;

  const GlassCard({
    super.key,
    required this.children,
    this.borderRadius = 30,
    this.padding,
    this.thickness = 5.0,
    this.refractiveIndex = 1.1,
    this.animateLiquid = false,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
      opacity: 1.0, 
      thickness: thickness,
      refractiveIndex: refractiveIndex,
      animateLiquid: animateLiquid,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          const SizedBox(height: 4), // Small extra buffer to prevent flex overflow
        ],
      ),
    );
  }
}
