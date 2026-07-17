import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:notes/app/theme/app_colors.dart';

/// Shared brand and glass primitives used by the app's top-level chrome.
abstract final class AppBrand {
  static const logoAsset = 'assets/icons/notes.jpg';
  static const logoAspectRatio = 988 / 1280;
}

/// The complete supplied P Note artwork, kept at its original aspect ratio.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    required this.height,
    this.borderRadius = 24,
    this.showShadow = true,
  });

  final double height;
  final double borderRadius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(borderRadius);

    return Semantics(
      image: true,
      label: 'P Note logo',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brandMagenta,
          borderRadius: radius,
          border: Border.all(
            color: Colors.white.withValues(alpha: .22),
            width: .75,
          ),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: .24),
                    blurRadius: 34,
                    spreadRadius: -4,
                    offset: const Offset(0, 14),
                  ),
                ]
              : const [],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Image.asset(
            AppBrand.logoAsset,
            height: height,
            width: height * AppBrand.logoAspectRatio,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

/// A compact square presentation of the supplied logo for navigation chrome.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 40, this.borderRadius = 13});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'P Note',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.brandMagenta,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: .22),
            width: .6,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          AppBrand.logoAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Calm color depth beneath translucent controls so the blur remains visible.
class AppBrandBackdrop extends StatelessWidget {
  const AppBrandBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    return ColoredBox(
      color: background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(.88, -1.04),
                  radius: 1.15,
                  colors: [
                    colors.primary.withValues(alpha: isDark ? .20 : .13),
                    background.withValues(alpha: 0),
                  ],
                  stops: const [0, .72],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.08, .94),
                  radius: 1.22,
                  colors: [
                    colors.secondary.withValues(alpha: isDark ? .13 : .075),
                    background.withValues(alpha: 0),
                  ],
                  stops: const [0, .74],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Translucent material for floating navigation and interactive controls.
class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.padding,
    this.blur = 22,
    this.opacity,
    this.tint,
    this.hasShadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double? opacity;
  final Color? tint;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    final base = tint ?? colors.surface;
    final resolvedOpacity = highContrast
        ? 1.0
        : (opacity ?? (isDark ? .68 : .72));
    final effectiveBlur = highContrast ? 0.0 : blur;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: isDark ? .30 : .10),
                  blurRadius: 28,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlur,
            sigmaY: effectiveBlur,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  base.withValues(
                    alpha: (resolvedOpacity + .10).clamp(0.0, 1.0),
                  ),
                  base.withValues(alpha: resolvedOpacity),
                ],
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color: highContrast
                    ? colors.outline
                    : isDark
                    ? Colors.white.withValues(alpha: .13)
                    : Colors.white.withValues(alpha: .78),
                width: .8,
              ),
            ),
            child: padding == null
                ? child
                : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}
