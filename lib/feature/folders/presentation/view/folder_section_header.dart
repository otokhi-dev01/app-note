part of 'folder_list_view.dart';

class _FolderSectionHeader extends StatelessWidget {
  final int count;
  final String sortLabel;
  final VoidCallback onSortPressed;

  const _FolderSectionHeader({
    required this.count,
    required this.sortLabel,
    required this.onSortPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 12, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Text(
                  'Folders',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(width: 8),
                _CountBadge(count: count),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            pressedOpacity: 0.5,
            onPressed: onSortPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  sortLabel,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 13,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
