part of 'main_tab_header_widget.dart';

class _HeaderPageIcon extends StatelessWidget {
  final IconData icon;
  final bool compact;

  const _HeaderPageIcon({required this.icon, required this.compact});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final double size = compact ? 44 : 48;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 15 : 17),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.17),
            colorScheme.primary.withValues(alpha: isDark ? 0.10 : 0.075),
          ],
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.18),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.13 : 0.10),
            blurRadius: 17,
            spreadRadius: -5,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 6,
            left: 10,
            right: 10,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.transparent,
                    Colors.white.withValues(alpha: isDark ? 0.18 : 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Icon(icon, size: compact ? 21 : 23, color: colorScheme.primary),
        ],
      ),
    );
  }
}
