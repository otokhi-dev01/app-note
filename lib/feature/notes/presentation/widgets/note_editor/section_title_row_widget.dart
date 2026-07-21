part of '../../view/note_editor_view.dart';

class _SectionTitleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData actionIcon;
  final String actionTooltip;
  final bool actionEnabled;
  final VoidCallback onAction;

  const _SectionTitleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionIcon,
    required this.actionTooltip,
    required this.actionEnabled,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    return Row(
      children: <Widget>[
        _SmallIconSurface(icon: icon, color: colors.primary),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: actionTooltip,
          enabled: actionEnabled,
          child: SizedBox(
            width: 38,
            height: 38,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              pressedOpacity: 0.45,
              onPressed: actionEnabled ? onAction : null,
              child: Icon(
                actionIcon,
                size: 22,
                color: actionEnabled
                    ? colors.primary
                    : colors.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
