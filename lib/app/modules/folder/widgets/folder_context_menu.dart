import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../widgets/ios_action_menu.dart';
import '../controllers/folder_controller.dart';
import 'folder_create_modal.dart';

class FolderContextMenu extends StatelessWidget {
  final FolderModel folder;
  final FolderController controller;

  const FolderContextMenu({
    super.key,
    required this.folder,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return IOSActionMenu(
      type: IOSMenuType.popup,
      actions: [
        IOSMenuAction(
          label: "Add Folder",
          icon: Icons.create_new_folder_outlined,
          onTap: () {
            Get.bottomSheet(
              FolderCreateModal(controller: controller),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            );
          },
        ),
        IOSMenuAction(
          label: "Move Folder",
          icon: Icons.drive_file_move_outlined,
          onTap: () {
            Get.back();
            controller.onMoveFolder(folder);
          },
        ),
        IOSMenuAction(
          label: "Rename Folder",
          icon: Icons.edit_note_rounded,
          onTap: () {
            Get.back();
            controller.onRenameFolder(folder);
          },
        ),
        IOSMenuAction(
          label: "Group By Date",
          icon: Icons.calendar_view_day_outlined,
          subtitle: "Default (On)",
          onTap: () {
            Get.back();
            controller.onToggleGroupByDate(folder);
          },
        ),
        IOSMenuAction(
          label: "Delete Folder",
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          onTap: () {
            Get.back();
            controller.onDeleteFolder(folder);
          },
        ),
        IOSMenuAction(
          label: "Convert to Smart Folder",
          icon: Icons.auto_fix_high_rounded,
          onTap: () {
            Get.back();
            controller.onConvertToSmartFolder(folder);
          },
        ),
      ],
    );
  }
}
