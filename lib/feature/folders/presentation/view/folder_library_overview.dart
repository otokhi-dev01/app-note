part of 'folder_list_view.dart';

class _LibraryOverview extends StatelessWidget {
  final int folderCount;
  final int noteCount;
  final int deletedCount;
  final bool allNotesSelected;
  final VoidCallback onAllNotesPressed;
  final VoidCallback onDeletedPressed;

  const _LibraryOverview({
    required this.folderCount,
    required this.noteCount,
    required this.deletedCount,
    required this.allNotesSelected,
    required this.onAllNotesPressed,
    required this.onDeletedPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: _GlassSurface(
        borderRadius: 26,
        padding: const EdgeInsets.all(14),
        tintColor: colors.surface.withValues(alpha: 0.66),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 13),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Your Library',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$folderCount '
                          '${folderCount == 1 ? 'folder' : 'folders'}'
                          ' • $noteCount '
                          '${noteCount == 1 ? 'note' : 'notes'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.rectangle_3_offgrid_fill,
                      size: 20,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: _LibraryActionTile(
                    icon: CupertinoIcons.doc_on_doc_fill,
                    title: 'All Notes',
                    value: noteCount.toString(),
                    selected: allNotesSelected,
                    onPressed: onAllNotesPressed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LibraryActionTile(
                    icon: CupertinoIcons.delete,
                    title: 'Deleted',
                    value: deletedCount.toString(),
                    destructive: true,
                    onPressed: onDeletedPressed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
