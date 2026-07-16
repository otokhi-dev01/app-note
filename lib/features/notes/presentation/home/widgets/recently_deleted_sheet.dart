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
    final noteCount = trashNotes.length;

    return _NotesSheet(
      maxHeightFactor: 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            title: 'Recently Deleted',
            subtitle: noteCount == 0
                ? 'Deleted notes will appear here.'
                : '$noteCount ${noteCount == 1 ? 'note' : 'notes'} waiting to be recovered.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trashNotes.isNotEmpty && onClearAll != null) ...[
                  _SheetIconButton(
                    icon: CupertinoIcons.trash,
                    tooltip: 'Empty trash',
                    onPressed: onClearAll!,
                    isDestructive: true,
                  ),
                  const SizedBox(width: 8),
                ],
                _SheetIconButton(
                  icon: CupertinoIcons.xmark,
                  tooltip: 'Close recently deleted',
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
          if (trashNotes.isEmpty)
            _EmptyTrashState(style: style)
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                itemCount: trashNotes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    final scheme = style.theme.colorScheme;
    final height = (MediaQuery.sizeOf(context).height * 0.42)
        .clamp(180.0, 300.0)
        .toDouble();

    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.trash_slash_fill,
              size: 34,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No Deleted Notes',
            style: style.theme.textTheme.titleLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notes you delete can be recovered from here.',
            textAlign: TextAlign.center,
            style: style.theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
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
    final scheme = style.theme.colorScheme;
    final title = note.title.trim().isEmpty ? 'Untitled Note' : note.title;
    final preview = note.content.trim().isEmpty
        ? 'No additional text'
        : note.content;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  CupertinoIcons.doc_text_fill,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style.theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: style.theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Recover',
                  icon: CupertinoIcons.arrow_counterclockwise,
                  color: scheme.primary,
                  onPressed: onRestore,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Delete',
                  icon: CupertinoIcons.trash,
                  color: scheme.error,
                  onPressed: onDelete,
                ),
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
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
