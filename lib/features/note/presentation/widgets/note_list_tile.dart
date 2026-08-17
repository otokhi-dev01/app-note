import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:Note/core/feedback/app_dialogs.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
import 'package:Note/routes/note_navigation.dart';
import 'package:Note/shared/widgets/app_note_tile.dart';
import 'package:Note/shared/widgets/ios_action_menu.dart';

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
      final isEditing = controller.isEditing.value;

      return AppNoteTile(
        note: note,
        isEditing: isEditing,
        isSelected: controller.selectedNoteIds.contains(note.id),
        showAttachmentThumbnail: true,
        onTap: () {
          if (isEditing) {
            controller.toggleSelectNote(note.id);
          } else {
            NoteNavigation.toDetail(note)?.then((value) {
              if (value == true) controller.fetchNotes(folderId: folderId);
            });
          }
        },
        onLongPress: () => _showContextMenu(context),
      );
    });
  }

  void _showContextMenu(BuildContext context) {
    IOSActionMenu.show(
      context: context,
      type: IOSMenuType.popup,
      title: "Note Options",
      actions: [
        IOSMenuAction(
          label: note.isPinned ? "Unpin Note" : "Pin Note",
          icon: note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
          onTap: () async {
            await controller.updateNoteState(note.id, isPinned: !note.isPinned);
            await controller.fetchNotes(folderId: folderId, refresh: true);
          },
        ),
        IOSMenuAction(
          label: "Move Note",
          icon: CupertinoIcons.folder_badge_plus,
          onTap: () {
            controller.selectOnly(note.id);
            controller.moveSelectedNotes(context, folderId);
          },
        ),
        IOSMenuAction(
          label: "Delete",
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onTap: () async {
            if (await AppDialogs.confirmDeleteNotes(1)) {
              controller.selectOnly(note.id);
              await controller.deleteSelectedNotes(folderId);
            }
          },
        ),
      ],
    );
  }
}
