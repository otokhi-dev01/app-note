import 'package:flutter/material.dart';

import '../../../../../core/presentation/widgets/app_ambient_orb.dart';

class LiquidBackground extends StatelessWidget {
  const LiquidBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.scaffoldBackgroundColor,
            Color.alphaBlend(
              colorScheme.primary.withValues(alpha: isDark ? 0.13 : 0.07),
              theme.scaffoldBackgroundColor,
            ),
            Color.alphaBlend(
              colorScheme.secondary.withValues(alpha: isDark ? 0.10 : 0.05),
              theme.scaffoldBackgroundColor,
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -90,
            child: AppAmbientOrb(
              size: 310,
              color: colorScheme.primary.withValues(
                alpha: isDark ? 0.15 : 0.10,
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -130,
            child: AppAmbientOrb(
              size: 280,
              color: colorScheme.secondary.withValues(
                alpha: isDark ? 0.12 : 0.07,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: AppAmbientOrb(
              size: 330,
              color: colorScheme.tertiary.withValues(
                alpha: isDark ? 0.12 : 0.07,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
