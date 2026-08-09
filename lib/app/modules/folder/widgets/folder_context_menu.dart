import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../widgets/ios_action_menu.dart';
import '../controllers/folder_controller.dart';
import 'folder_create_modal.dart';

class FolderContextMenu extends StatelessWidget {
  final FolderModel folder;
  final FolderController controller;

  const FolderContextMenu({super.key, required this.folder, required this.controller});

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
            );
          },
        ),
        IOSMenuAction(
          label: "Move This Folder",
          icon: Icons.folder_open_outlined,
          onTap: () => controller.onMoveFolder(folder),
        ),
        IOSMenuAction(
          label: "Rename",
          icon: Icons.edit_outlined,
          onTap: () => controller.onRenameFolder(folder),
        ),
        IOSMenuAction(
          label: "Group By Date",
          icon: Icons.calendar_view_day_outlined,
          subtitle: "Default (On)",
          onTap: () => controller.onToggleGroupByDate(folder),
        ),
        IOSMenuAction(
          label: "Delete",
          icon: Icons.delete_outline,
          isDestructive: true,
          onTap: () => controller.onDeleteFolder(folder),
        ),
        IOSMenuAction(
          label: "Convert to Smart Folder",
          icon: Icons.settings_outlined,
          onTap: () => controller.onConvertToSmartFolder(folder),
        ),
      ],
    );
  }
}
