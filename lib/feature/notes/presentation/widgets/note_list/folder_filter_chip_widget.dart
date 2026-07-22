part of '../../view/note_list_view.dart';

class _FolderFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FolderFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor = selected
        ? colors.primary.withValues(alpha: isDark ? 0.22 : 0.14)
        : colors.surface.withValues(alpha: isDark ? 0.65 : 0.55);

    final Color foregroundColor = selected
        ? colors.primary
        : colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: AppGlassSurface(
        borderRadius: 22,
        padding: EdgeInsets.zero,
        blur: 20,
        tintColor: backgroundColor,
        borderColor: selected ? colors.primary.withValues(alpha: 0.45) : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            splashColor: colors.primary.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    icon,
                    size: 18,
                    color: foregroundColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
