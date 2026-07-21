part of 'liquid_bottom_navigation_widget.dart';

class _CreateNoteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateNoteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'Create note',
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.70,
        onPressed: onPressed,
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: colors.surface, width: 5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.primary.withValues(alpha: isDark ? 0.38 : 0.28),
                blurRadius: 24,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: colors.shadow.withValues(alpha: isDark ? 0.24 : 0.12),
                blurRadius: 18,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(CupertinoIcons.add, size: 32, color: colors.onPrimary),
        ),
      ),
    );
  }
}
