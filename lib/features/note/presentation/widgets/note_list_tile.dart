import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_item_context_menu.dart';
import 'package:Note/routes/note_navigation.dart';
import 'package:Note/shared/widgets/app_note_tile.dart';

/// A note row in the folder's note list: tap to open, long-press for actions.
class NoteListTile extends StatelessWidget {
  final Note note;
  final int folderId;
  final NoteController controller;

  const NoteListTile({
    super.key,
    required this.note,
    required this.folderId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return NoteItemContextMenu(
        note: note,
        folderId: folderId,
        controller: controller,
        triggerBuilder: (context, openMenu) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (controller.isEditing.value) {
              controller.toggleSelectNote(note.id);
            } else {
              NoteNavigation.toDetail(
                note,
              )?.then((_) => controller.fetchNotes(folderId: folderId));
            }
          },
          onLongPress: controller.isEditing.value ? null : openMenu,
          child: AppNoteTile(
            note: note,
            isEditing: controller.isEditing.value,
            isSelected: controller.isSelected(note.id),
            showAttachmentThumbnail: true,
          ),
        ),
      );
    });
  }

  // DELETED: _showContextMenu as it's now handled by NoteItemContextMenu
}
