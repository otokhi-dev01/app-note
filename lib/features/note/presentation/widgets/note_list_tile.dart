import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_item_context_menu.dart';
import 'package:Note/routes/note_navigation.dart';
import 'package:Note/shared/widgets/app_note_tile.dart';

class NoteListTile extends StatelessWidget {
  final Note note;
  final int folderId;
  final NoteController controller;
  final bool showChevron;

  const NoteListTile({
    super.key,
    required this.note,
    required this.folderId,
    required this.controller,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEditing = controller.isEditing.value;
      final isSelected = controller.isSelected(note.id);

      return NoteItemContextMenu(
        note: note,
        folderId: folderId,
        controller: controller,
        triggerBuilder: (context, openMenu) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (isEditing) {
              controller.toggleSelectNote(note.id);
            } else {
              NoteNavigation.toDetail(
                note,
              )?.then((_) => controller.fetchNotes(folderId: folderId));
            }
          },
          onLongPress: isEditing ? null : openMenu,
          child: AppNoteTile(
            note: note,
            isEditing: isEditing,
            isSelected: isSelected,
            showAttachmentThumbnail: true,
            showChevron: showChevron,
          ),
        ),
      );
    });
  }
}
