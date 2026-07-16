part of 'home_sheets.dart';

class RecentlyDeletedSheet extends StatelessWidget {
  const RecentlyDeletedSheet({
    super.key,
    required this.notes,
    required this.onRestore,
    required this.onDeletePermanently,
    this.onClearAll,
  });

  final List<Note> notes;
  final ValueChanged<Note> onRestore;
  final ValueChanged<Note> onDeletePermanently;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final trashNotes = notes.toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: style.placeholder,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recently Deleted',
                      style: style.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    if (trashNotes.isNotEmpty && onClearAll != null)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: onClearAll,
                        child: const Text(
                          'Empty Trash',
                          style: TextStyle(
                            color: HomeStyle.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: HomeStyle.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          if (trashNotes.isEmpty)
            _EmptyTrashState(style: style)
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: trashNotes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final note = trashNotes[index];
                  return _DeletedNoteCard(
                    style: style,
                    note: note,
                    onRestore: () => onRestore(note),
                    onDelete: () => _confirmDelete(context, note),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Note note) {
    Get.dialog(
      CupertinoAlertDialog(
        title: const Text('Permanently Delete?'),
        content: const Text(
          'This action cannot be undone and will remove the note forever.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              onDeletePermanently(note);
              Get.back();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrashState extends StatelessWidget {
  const _EmptyTrashState({required this.style});

  final HomeStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(CupertinoIcons.trash_slash, size: 64, color: style.placeholder),
          const SizedBox(height: 16),
          Text(
            'Trash is empty',
            style: style.theme.textTheme.titleMedium?.copyWith(
              color: style.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletedNoteCard extends StatelessWidget {
  const _DeletedNoteCard({
    required this.style,
    required this.note,
    required this.onRestore,
    required this.onDelete,
  });

  final HomeStyle style;
  final Note note;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title.isEmpty ? 'Untitled' : note.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            note.content.isEmpty ? 'No content' : note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: style.secondaryText,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                label: 'Restore',
                icon: CupertinoIcons.arrow_counterclockwise,
                color: HomeStyle.blue,
                onPressed: onRestore,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                label: 'Delete',
                icon: CupertinoIcons.trash,
                color: HomeStyle.red,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minimumSize: Size.zero,
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
