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
    final bool isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
      child: _GlassSurface(
        borderRadius: 28,
        padding: const EdgeInsets.all(16),
        tintColor: colors.surface.withValues(alpha: isDark ? 0.68 : 0.58),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 16),
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
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$folderCount '
                          '${folderCount == 1 ? 'folder' : 'folders'}'
                          ' • $noteCount '
                          '${noteCount == 1 ? 'note' : 'notes'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.rectangle_3_offgrid_fill,
                      size: 20,
                      color: colors.primary,
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
                const SizedBox(width: 12),
                Expanded(
                  child: _LibraryActionTile(
                    icon: CupertinoIcons.trash_fill,
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
