part of '../../view/note_editor_view.dart';

class _NoteMetadataCard extends StatelessWidget {
  final NoteEditorController controller;

  const _NoteMetadataCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    final note = controller.note.value;

    if (note == null) {
      return const SizedBox.shrink();
    }

    final DateTime? timestamp = note.updatedAt ?? note.createdAt;

    final String folder = note.folderName.trim().isNotEmpty
        ? note.folderName.trim()
        : 'Folder #${note.folderId}';

    final int attachmentCount = note.attachmentCount > 0
        ? note.attachmentCount
        : controller.attachmentBlocks.length;

    return AppSurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: <Widget>[
          _SmallIconSurface(
            icon: CupertinoIcons.folder_fill,
            color: colors.primary,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              folder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (attachmentCount > 0) ...<Widget>[
            Icon(
              CupertinoIcons.paperclip,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 3),
            Text(
              attachmentCount.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (timestamp != null)
            Text(
              _friendlyDate(timestamp.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
