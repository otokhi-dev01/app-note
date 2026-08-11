import 'package:flutter/cupertino.dart';
import '../../../widgets/ios_action_menu.dart';
import '../controllers/note_detail_controller.dart';
import 'package:get/get.dart';

class NoteDetailMorePopup extends StatelessWidget {
  final NoteDetailController controller;

  const NoteDetailMorePopup({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => IOSActionMenu(
        type: IOSMenuType.popup,
        actions: [
          IOSMenuAction(
            label: controller.isPinned.value ? "Unpin" : "Pin",
            icon: controller.isPinned.value
                ? CupertinoIcons.pin_slash
                : CupertinoIcons.pin,
            onTap: controller.togglePin,
          ),
          IOSMenuAction(
            label: controller.isArchived.value ? "Unarchive" : "Archive",
            icon: controller.isArchived.value
                ? CupertinoIcons.archivebox_fill
                : CupertinoIcons.archivebox,
            onTap: controller.toggleArchive,
          ),
          IOSMenuAction(
            label: controller.isLocked.value ? "Unlock" : "Lock",
            icon: controller.isLocked.value
                ? CupertinoIcons.lock_fill
                : CupertinoIcons.lock,
            onTap: controller.toggleLock,
          ),
          IOSMenuAction(
            label: "Move",
            icon: CupertinoIcons.folder_badge_plus,
            onTap: controller.moveNote,
          ),
          IOSMenuAction(
            label: "Find in Note",
            icon: CupertinoIcons.doc_text_search,
            onTap: controller.toggleSearch,
          ),
          IOSMenuAction(
            label: "Delete",
            icon: CupertinoIcons.trash,
            isDestructive: true,
            onTap: controller.deleteNote,
          ),
        ],
      ),
    );
  }
}
