import 'package:flutter/cupertino.dart';
import '../../../widgets/ios_action_menu.dart';
import '../controllers/note_detail_controller.dart';

class NoteDetailMorePopup extends StatelessWidget {
  final NoteDetailController controller;

  const NoteDetailMorePopup({super.key, required this.controller});

  static void show({
    required BuildContext context,
    required NoteDetailController controller,
  }) {
    IOSActionMenu.show(
      context: context,
      type: IOSMenuType.popup,
      actions: [
        // 1. Pin Logic
        IOSMenuAction(
          label: controller.isPinned.value ? "Unpin" : "Pin",
          icon: controller.isPinned.value
              ? CupertinoIcons.pin_slash
              : CupertinoIcons.pin,
          onTap: controller.togglePin,
        ),
        // 2. Archive Logic
        IOSMenuAction(
          label: controller.isArchived.value ? "Unarchive" : "Archive",
          icon: controller.isArchived.value
              ? CupertinoIcons.archivebox_fill
              : CupertinoIcons.archivebox,
          onTap: controller.toggleArchive,
        ),
        // 3. Lock Logic
        IOSMenuAction(
          label: controller.isLocked.value ? "Unlock" : "Lock",
          icon: controller.isLocked.value
              ? CupertinoIcons.lock_fill
              : CupertinoIcons.lock,
          onTap: controller.toggleLock,
        ),
        // 4. Move Logic
        IOSMenuAction(
          label: "Move",
          icon: CupertinoIcons.folder,
          onTap: controller.moveNote,
        ),
        // 5. Find in Note Logic
        IOSMenuAction(
          label: "Find in Note",
          icon: CupertinoIcons.doc_text_search,
          onTap: controller.toggleSearch,
        ),
        // 6. Delete Logic (Destructive)
        IOSMenuAction(
          label: "Delete",
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onTap: controller.deleteNote,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
