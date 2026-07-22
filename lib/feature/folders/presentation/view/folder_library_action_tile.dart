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
    final bool isDark = theme.brightness == Brightness.dark;

    final Color accent = destructive ? colors.error : colors.primary;
    
    final Color backgroundColor = destructive
        ? colors.error.withValues(alpha: isDark ? 0.16 : 0.08)
        : selected
        ? colors.primary.withValues(alpha: isDark ? 0.18 : 0.10)
        : colors.onSurface.withValues(alpha: 0.05);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 22, color: accent),
                  const Spacer(),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 14,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
