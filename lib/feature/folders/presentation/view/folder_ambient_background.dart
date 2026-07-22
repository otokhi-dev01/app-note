part of 'folder_list_view.dart';

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color pageColor = theme.scaffoldBackgroundColor;
    final bool isDark = theme.brightness == Brightness.dark;

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    pageColor,
                    Color.alphaBlend(
                      colors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                      pageColor,
                    ),
                    Color.alphaBlend(
                      colors.secondary.withValues(alpha: isDark ? 0.06 : 0.03),
                      pageColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -80,
            child: AppAmbientOrb(
              size: 280,
              color: colors.primary.withValues(alpha: isDark ? 0.12 : 0.07),
            ),
          ),
          Positioned(
            top: 350,
            left: -120,
            child: AppAmbientOrb(
              size: 320,
              color: colors.secondary.withValues(alpha: isDark ? 0.08 : 0.05),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -90,
            child: AppAmbientOrb(
              size: 240,
              color: colors.tertiary.withValues(alpha: isDark ? 0.06 : 0.04),
            ),
          ),
        ],
      ),
    );
  }
}
