part of '../../view/note_list_view.dart';

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 12, 12),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.8),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }
}
