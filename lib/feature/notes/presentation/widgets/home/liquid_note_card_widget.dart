import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/note_entity.dart';

class LiquidNoteCard extends StatelessWidget {
  final NoteEntity note;
  final String folderName;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onArchive;
  final VoidCallback onLock;

  const LiquidNoteCard({
    super.key,
    required this.note,
    required this.folderName,
    required this.onTap,
    required this.onTogglePin,
    required this.onArchive,
    required this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool isDark = theme.brightness == Brightness.dark;

    final Color cardColor = isDark
        ? const Color(0xFF1B1D22).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.87);

    final int attachmentCount = note.attachmentCount > 0
        ? note.attachmentCount
        : note.content.where((Map<String, dynamic> block) {
            return block['type']?.toString().toLowerCase() == 'attachment';
          }).length;
    final DateTime? timestamp = note.updatedAt ?? note.createdAt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: note.isPinned
                  ? colorScheme.primary.withValues(alpha: 0.42)
                  : colorScheme.outlineVariant.withValues(
                      alpha: isDark ? 0.20 : 0.38,
                    ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.045),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.72,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      note.isLocked
                          ? Icons.lock_outline_rounded
                          : Icons.description_outlined,
                      size: 21,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title.trim().isEmpty
                              ? 'Untitled Note'
                              : note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          folderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _NoteMenuButton(
                    note: note,
                    onTogglePin: onTogglePin,
                    onArchive: onArchive,
                    onLock: onLock,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _notePreview(note),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (note.isPinned ||
                  note.isArchived ||
                  note.isLocked ||
                  attachmentCount > 0 ||
                  timestamp != null) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (note.isPinned)
                      _StateBadge(
                        icon: Icons.push_pin_outlined,
                        label: 'Pinned',
                        color: colorScheme.primary,
                      ),
                    if (note.isArchived)
                      _StateBadge(
                        icon: Icons.archive_outlined,
                        label: 'Archived',
                        color: colorScheme.secondary,
                      ),
                    if (note.isLocked)
                      _StateBadge(
                        icon: Icons.lock_outline_rounded,
                        label: 'Locked',
                        color: colorScheme.tertiary,
                      ),
                    if (attachmentCount > 0)
                      _StateBadge(
                        icon: Icons.attach_file_rounded,
                        label: '$attachmentCount',
                        color: colorScheme.secondary,
                      ),
                    if (timestamp != null)
                      _StateBadge(
                        icon: Icons.schedule_rounded,
                        label: MaterialLocalizations.of(
                          context,
                        ).formatShortDate(timestamp),
                        color: colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _notePreview(NoteEntity note) {
    if (note.isLocked) {
      return 'This note is locked.';
    }

    for (final Map<String, dynamic> block in note.content) {
      if (block['type'] == 'text') {
        final String text = block['text']?.toString().trim() ?? '';

        if (text.isNotEmpty) {
          return text;
        }
      }

      if (block['type'] == 'checklist') {
        final dynamic rawItems = block['items'];

        if (rawItems is List) {
          final int complete = rawItems.where((dynamic item) {
            return item is Map && item['checked'] == true;
          }).length;

          return '$complete of ${rawItems.length} checklist tasks completed';
        }

        return 'Checklist';
      }

      if (block['type'] == 'attachment') {
        return 'Attachment';
      }
    }

    if (note.attachmentCount > 0) {
      return '${note.attachmentCount} '
          '${note.attachmentCount == 1 ? 'attachment' : 'attachments'}';
    }

    return 'Tap to start writing.';
  }
}

class _NoteMenuButton extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback onTogglePin;
  final VoidCallback onArchive;
  final VoidCallback onLock;

  const _NoteMenuButton({
    required this.note,
    required this.onTogglePin,
    required this.onArchive,
    required this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        showCupertinoModalPopup<void>(
          context: context,
          builder: (BuildContext sheetContext) {
            return CupertinoActionSheet(
              title: Text(
                note.title.trim().isEmpty ? 'Untitled Note' : note.title,
              ),
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onTogglePin();
                  },
                  child: Text(note.isPinned ? 'Unpin Note' : 'Pin Note'),
                ),
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onArchive();
                  },
                  child: Text(
                    note.isArchived ? 'Remove from Archive' : 'Archive Note',
                  ),
                ),
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onLock();
                  },
                  child: Text(note.isLocked ? 'Unlock Note' : 'Lock Note'),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Cancel'),
              ),
            );
          },
        );
      },
      child: Icon(
        Icons.more_horiz_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StateBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
