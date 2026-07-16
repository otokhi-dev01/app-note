import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/features/library/application/library_coordinator.dart';
import 'package:notes/features/library/application/library_note_queries.dart';

import '../library_helpers.dart';
import '../widgets/library_components.dart';

class NoteHistoryView extends GetView<LibraryCoordinator> {
  const NoteHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return LibraryScaffold(
      title: 'Recent Activity',
      child: Obx(() {
        final notes = [...controller.notes]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
          children: [
            const LibraryFeatureIntro(
              title: 'Note History',
              subtitle: 'Recent saved updates from your note repository',
              icon: CupertinoIcons.time,
              compact: true,
            ),
            const SizedBox(height: 20),
            if (notes.isEmpty)
              const LibraryFeatureEmpty(
                message: 'Your recent note activity will appear here.',
              )
            else
              ...groupNotesByDay(notes).entries.map((group) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 9),
                      child: Text(
                        group.key.toUpperCase(),
                        style: libraryFeatureEyebrow,
                      ),
                    ),
                    LibrarySurface(
                      child: Column(
                        children: group.value.asMap().entries.map((entry) {
                          final note = entry.value;
                          return Column(
                            children: [
                              ListTile(
                                onTap: () => controller.openNote(note),
                                leading: const LibraryFeatureIcon(
                                  CupertinoIcons.doc_text,
                                ),
                                title: Text(
                                  note.title.isEmpty ? 'Untitled' : note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  'Updated at ${DateFormat.jm().format(note.updatedAt)}',
                                ),
                                trailing: const Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 15,
                                ),
                              ),
                              if (entry.key != group.value.length - 1)
                                const Divider(height: 1, indent: 70),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              }),
            const SizedBox(height: 24),
            const Text(
              'Full version snapshots require a server or database history contract. This timeline shows actual saved note updates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.subtitle, height: 1.4),
            ),
          ],
        );
      }),
    );
  }
}
