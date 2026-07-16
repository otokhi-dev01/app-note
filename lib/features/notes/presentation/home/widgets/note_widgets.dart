part of '../home_view.dart';

class _NoteGroup extends StatelessWidget {
  const _NoteGroup({required this.notes, required this.controller});

  final List<Note> notes;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: notes.asMap().entries.map((entry) {
          final note = entry.value;
          return _NoteRow(
            note: note,
            isLast: entry.key == notes.length - 1,
            onTap: () => controller.openNote(note),
            onAction: (action) => _handleNoteAction(action, note, controller),
          );
        }).toList(),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.note,
    required this.isLast,
    required this.onTap,
    required this.onAction,
  });

  final Note note;
  final bool isLast;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  if (note.imagePaths.isNotEmpty) ...[
                    ImageHelper.buildSafeImage(
                      note.imagePaths.first,
                      width: 48,
                      height: 48,
                      radius: 9,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (note.isPinned) ...[
                              const Icon(
                                CupertinoIcons.pin_fill,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Expanded(
                              child: Text(
                                note.title.isEmpty ? 'Untitled' : note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_shortDate(note.updatedAt)}  ${note.content.isEmpty ? 'No additional text' : note.content}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Note actions',
                    onSelected: onAction,
                    icon: const Icon(
                      CupertinoIcons.ellipsis,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(note.isPinned ? 'Unpin' : 'Pin'),
                      ),
                      const PopupMenuItem(value: 'share', child: Text('Share')),
                      const PopupMenuItem(value: 'move', child: Text('Move')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AppColors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}

class _NoteGalleryCard extends StatelessWidget {
  const _NoteGalleryCard({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.imagePaths.isNotEmpty)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageHelper.buildSafeImage(
                      note.imagePaths.first,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.doc_text,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                note.content.isEmpty
                    ? _shortDate(note.updatedAt)
                    : note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedCard extends StatelessWidget {
  const _PinnedCard({
    required this.note,
    required this.onTap,
    required this.onShare,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.pin_fill,
                    size: 18,
                    color: colors.onPrimaryContainer,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onShare,
                    icon: Icon(
                      CupertinoIcons.share,
                      size: 20,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                note.content.isEmpty ? 'No additional text' : note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Updated ${_shortDate(note.updatedAt)}',
                style: TextStyle(
                  color: colors.onPrimaryContainer.withValues(alpha: .68),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
