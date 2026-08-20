import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
import 'package:Note/routes/note_navigation.dart';
import 'package:Note/shared/widgets/app_note_tile.dart';

/// A note row in the archive. Same tile as the notes list, wider gutter.
class ArchiveNoteTile extends StatelessWidget {
  final Note note;
  final NoteController controller;

  const ArchiveNoteTile({
    super.key,
    required this.note,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEditing = controller.isEditing.value;

      return AppNoteTile(
        note: note,
        isEditing: isEditing,
        isSelected: controller.selectedNoteIds.contains(note.id),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        onTap: () {
          if (isEditing) {
            controller.toggleSelectNote(note.id);
          } else {
            // Always refresh, not just when the popped result is `true` —
            // an iOS swipe-back gesture leaves this note without ever
            // running the button's explicit `Get.back(result: true)`, so
            // relying on that alone missed edits made in the detail screen.
            NoteNavigation.toDetail(
              note,
            )?.then((_) => controller.fetchNotes(refresh: true));
          }
        },
      );
    });
  }
}
