part of 'main_tab_header_widget.dart';

class _HeaderLogo extends StatelessWidget {
  final String assetPath;
  final bool compact;

  const _HeaderLogo({required this.assetPath, required this.compact});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final double size = compact ? 44 : 48;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 15 : 17),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: isDark ? 0.12 : 0.92),
            colorScheme.surface.withValues(alpha: isDark ? 0.50 : 0.65),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.72),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.07),
            blurRadius: 14,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 11 : 13),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return Icon(
                  CupertinoIcons.doc_text_fill,
                  color: colorScheme.primary,
                  size: 22,
                );
              },
        ),
      ),
    );
  }
}
