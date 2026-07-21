import 'dart:ui';

import 'package:flutter/material.dart';

/// A reusable glow used by liquid and authentication backgrounds.
class AppAmbientOrb extends StatelessWidget {
  const AppAmbientOrb({
    required this.size,
    required this.color,
    this.blurSigma,
    super.key,
  });

  const AppAmbientOrb.blurred({
    required this.size,
    required this.color,
    this.blurSigma = 60,
    super.key,
  });

  final double size;
  final Color color;
  final double? blurSigma;

  @override
  Widget build(BuildContext context) {
    final Widget orb = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: blurSigma == null ? null : color,
        gradient: blurSigma == null
            ? RadialGradient(colors: <Color>[color, color.withValues(alpha: 0)])
            : null,
      ),
    );

    return IgnorePointer(
      child: blurSigma == null
          ? orb
          : ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blurSigma!,
                sigmaY: blurSigma!,
              ),
              child: orb,
            ),
    );
  }
}
