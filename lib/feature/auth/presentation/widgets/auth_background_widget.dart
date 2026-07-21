import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_ambient_orb.dart';

class AuthBackgroundWidget extends StatelessWidget {
  const AuthBackgroundWidget({super.key});

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
          colors: <Color>[
            theme.scaffoldBackgroundColor,
            Color.alphaBlend(
              colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.07),
              theme.scaffoldBackgroundColor,
            ),
            Color.alphaBlend(
              colorScheme.secondary.withValues(alpha: isDark ? 0.10 : 0.045),
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
            child: AppAmbientOrb(
              size: 330,
              color: colorScheme.primary.withValues(
                alpha: isDark ? 0.18 : 0.11,
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -140,
            child: AppAmbientOrb(
              size: 300,
              color: colorScheme.secondary.withValues(
                alpha: isDark ? 0.14 : 0.075,
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            right: -110,
            child: AppAmbientOrb(
              size: 360,
              color: colorScheme.tertiary.withValues(
                alpha: isDark ? 0.13 : 0.065,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
