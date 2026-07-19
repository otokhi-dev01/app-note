import 'package:flutter/material.dart';

class AppLiquidBackgroundWidget extends StatelessWidget {
  const AppLiquidBackgroundWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.scaffoldBackgroundColor,
            Color.alphaBlend(
              colorScheme.primary.withValues(
                alpha: isDark ? 0.14 : 0.07,
              ),
              theme.scaffoldBackgroundColor,
            ),
            Color.alphaBlend(
              colorScheme.secondary.withValues(
                alpha: isDark ? 0.10 : 0.045,
              ),
              theme.scaffoldBackgroundColor,
            ),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -130,
            right: -100,
            child: _AmbientOrb(
              size: 330,
              color: colorScheme.primary.withValues(
                alpha: isDark ? 0.18 : 0.10,
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -140,
            child: _AmbientOrb(
              size: 300,
              color: colorScheme.secondary.withValues(
                alpha: isDark ? 0.14 : 0.07,
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            right: -110,
            child: _AmbientOrb(
              size: 360,
              color: colorScheme.tertiary.withValues(
                alpha: isDark ? 0.13 : 0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}