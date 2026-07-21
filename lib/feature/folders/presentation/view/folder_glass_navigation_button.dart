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
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.55,
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        child: _GlassSurface(
          borderRadius: 18,
          padding: EdgeInsets.zero,
          tintColor: primary
              ? colors.primary.withValues(alpha: 0.14)
              : colors.surface.withValues(alpha: 0.74),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 19, color: colors.primary),
          ),
        ),
      ),
    );
  }
}
