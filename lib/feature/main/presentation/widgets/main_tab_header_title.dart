part of 'main_tab_header_widget.dart';

class _HeaderTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;
  final bool veryCompact;

  const _HeaderTitle({
    required this.title,
    required this.subtitle,
    required this.compact,
    required this.veryCompact,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool hasSubtitle = subtitle.trim().isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontSize: compact ? 18 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.55,
            height: 1.05,
          ),
        ),
        if (hasSubtitle && !veryCompact) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.08,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}
