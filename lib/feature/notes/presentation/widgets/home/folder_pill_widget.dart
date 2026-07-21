part of 'home_folder_strip_widget.dart';

class _FolderPill extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FolderPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool isDark = theme.brightness == Brightness.dark;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.28 : 0.16)
              : colorScheme.surface.withValues(alpha: isDark ? 0.48 : 0.64),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.62)
                : colorScheme.outlineVariant.withValues(alpha: 0.34),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? color
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? color : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 7),
              Text(
                count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? color : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
