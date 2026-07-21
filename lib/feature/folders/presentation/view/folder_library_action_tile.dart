part of 'folder_list_view.dart';

class _LibraryActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool selected;
  final bool destructive;
  final VoidCallback onPressed;

  const _LibraryActionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onPressed,
    this.selected = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accent = destructive ? colors.error : colors.primary;
    final Color backgroundColor = destructive
        ? colors.errorContainer.withValues(alpha: 0.58)
        : selected
        ? colors.primaryContainer.withValues(alpha: 0.72)
        : colors.surfaceContainerHighest.withValues(alpha: 0.52);
    final Color foregroundColor = destructive
        ? colors.onErrorContainer
        : selected
        ? colors.onPrimaryContainer
        : colors.onSurface;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        splashColor: accent.withValues(alpha: 0.08),
        highlightColor: accent.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 20, color: accent),
                  const Spacer(),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 14,
                    color: foregroundColor.withValues(alpha: 0.55),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
