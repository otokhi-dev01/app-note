part of 'folder_list_view.dart';

class _FolderFooter extends StatelessWidget {
  final int folderCount;
  final int noteCount;

  const _FolderFooter({required this.folderCount, required this.noteCount});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        '$folderCount '
        '${folderCount == 1 ? 'folder' : 'folders'}'
        ' • $noteCount '
        '${noteCount == 1 ? 'note' : 'notes'}',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
