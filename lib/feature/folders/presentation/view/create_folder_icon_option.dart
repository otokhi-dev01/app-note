part of 'create_folder_view.dart';

class _IconOption extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconOption({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.18)
                : isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.20),
                      blurRadius: 10,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 24,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
