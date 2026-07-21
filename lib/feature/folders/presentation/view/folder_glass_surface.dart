part of 'folder_list_view.dart';

class _GlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? tintColor;
  final Color? borderColor;

  const _GlassSurface({
    required this.child,
    this.borderRadius = 22,
    this.padding = const EdgeInsets.all(16),
    this.tintColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.shadow.withValues(alpha: isDark ? 0.14 : 0.07),
              blurRadius: 24,
              spreadRadius: -10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color:
                    tintColor ??
                    colors.surface.withValues(alpha: isDark ? 0.76 : 0.68),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color:
                      borderColor ??
                      colors.outlineVariant.withValues(
                        alpha: isDark ? 0.58 : 0.72,
                      ),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
