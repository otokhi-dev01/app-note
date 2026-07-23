part of '../../view/note_list_view.dart';

class _RecentNotesList extends StatelessWidget {
  final List<NoteEntity> notes;
  final List<FolderEntity> folders;

  const _RecentNotesList({required this.notes, required this.folders});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          final folder = _folderForNote(note: note, folders: folders);
          final color = _parseFolderColor(folder?.colorValue ?? '', colors.primary);

          return _RecentNoteCard(
            note: note,
            folderColor: color,
          );
        },
      ),
    );
  }

  FolderEntity? _folderForNote({
    required NoteEntity note,
    required List<FolderEntity> folders,
  }) {
    for (final FolderEntity folder in folders) {
      if (folder.id == note.folderId) {
        return folder;
      }
    }
    return null;
  }
}

class _RecentNoteCard extends StatelessWidget {
  final NoteEntity note;
  final Color folderColor;

  const _RecentNoteCard({required this.note, required this.folderColor});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
             HapticFeedback.selectionClick();
             Get.find<HomeController>().openNote(note.id);
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                    letterSpacing: -0.4,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    _notePreview(note),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      height: 1.4,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      _friendlyDate(note.updatedAt ?? note.createdAt ?? DateTime.now()),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (note.isPinned)
                      Icon(
                        CupertinoIcons.star_fill,
                        size: 13,
                        color: colors.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
