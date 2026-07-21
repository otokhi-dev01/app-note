part of 'folder_list_view.dart';

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 25, minHeight: 25),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 999 ? '999+' : count.toString(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
