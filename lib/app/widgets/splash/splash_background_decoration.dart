import 'package:flutter/material.dart';

import 'splash_glow_circle.dart';

class SplashBackgroundDecoration extends StatelessWidget {
  const SplashBackgroundDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -90,
            right: -70,
            child: SplashGlowCircle(
              size: 230,
              color: colors.primary.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            left: -100,
            bottom: 40,
            child: SplashGlowCircle(
              size: 260,
              color: colors.secondary.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}
