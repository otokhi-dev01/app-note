import 'package:flutter/material.dart';

class SplashAnimatedLogo extends StatelessWidget {
  const SplashAnimatedLogo({required this.pulseAnimation, super.key});

  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (BuildContext context, Widget? child) {
        final double value = pulseAnimation.value;

        return Transform.scale(
          scale: 1 + (value * 0.04),
          child: Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  colors.primary,
                  colors.primary.withValues(alpha: 0.72),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.30),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(
                    alpha: 0.18 + (value * 0.12),
                  ),
                  blurRadius: 30 + (value * 12),
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  top: 14,
                  right: 18,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Icon(Icons.note_alt_rounded, size: 66, color: colors.onPrimary),
              ],
            ),
          ),
        );
      },
    );
  }
}
