import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/features/library/application/library_coordinator.dart';
import 'package:notes/features/library/application/library_note_queries.dart';

import '../widgets/library_components.dart';

class NoteHistoryView extends GetView<LibraryCoordinator> {
  const NoteHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LibraryScaffold(
      title: 'Recent Activity',
      child: Obx(() {
        final notes = [...controller.notes]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          children: [
            const LibraryFeatureIntro(
              title: 'Note History',
              subtitle: 'Recent saved updates from your note repository',
              icon: CupertinoIcons.time,
              compact: true,
            ),
            const SizedBox(height: 22),
            if (notes.isEmpty)
              const LibraryFeatureEmpty(
                message: 'Your recent note activity will appear here.',
                icon: CupertinoIcons.clock,
              )
            else
              ...groupNotesByDay(notes).entries.map((group) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LibrarySectionHeader(title: group.key),
                    LibrarySurface(
                      child: Column(
                        children: group.value.asMap().entries.map((entry) {
                          final note = entry.value;
                          return Column(
                            children: [
                              ListTile(
                                onTap: () => controller.openNote(note),
                                minTileHeight: 72,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                leading: const LibraryFeatureIcon(
                                  CupertinoIcons.doc_text,
                                  size: 42,
                                  iconSize: 20,
                                ),
                                title: Text(
                                  note.title.isEmpty ? 'Untitled' : note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Updated at ${DateFormat.jm().format(note.updatedAt)}',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Icon(
                                  CupertinoIcons.chevron_right,
                                  color: colors.onSurfaceVariant.withValues(
                                    alpha: .72,
                                  ),
                                  size: 14,
                                ),
                              ),
                              if (entry.key != group.value.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 74,
                                  color: colors.outlineVariant.withValues(
                                    alpha: .55,
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              }),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    color: colors.onSurfaceVariant,
                    size: 19,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'This timeline shows actual saved note updates. Full version snapshots need database-backed history.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
