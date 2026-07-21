part of 'folder_list_view.dart';

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color pageColor = theme.scaffoldBackgroundColor;

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color.alphaBlend(
                      colors.primary.withValues(alpha: 0.025),
                      pageColor,
                    ),
                    pageColor,
                    Color.alphaBlend(
                      colors.tertiary.withValues(alpha: 0.018),
                      pageColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -75,
            child: AppAmbientOrb.blurred(
              size: 230,
              color: colors.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 300,
            left: -110,
            child: AppAmbientOrb.blurred(
              size: 260,
              color: colors.tertiary.withValues(alpha: 0.055),
            ),
          ),
        ],
      ),
    );
  }
}
