part of 'folder_list_view.dart';

class _GlassNavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onPressed;

  const _GlassNavigationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.65,
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        child: _GlassSurface(
          borderRadius: 22,
          padding: EdgeInsets.zero,
          tintColor: primary
              ? colors.primary.withValues(alpha: isDark ? 0.22 : 0.14)
              : colors.surface.withValues(alpha: isDark ? 0.72 : 0.62),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: primary ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
