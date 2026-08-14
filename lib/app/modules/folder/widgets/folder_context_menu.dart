import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../widgets/ios_action_menu.dart';
import '../controllers/folder_controller.dart';

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
          label: "Move Folder",
          icon:  CupertinoIcons.folder,
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
          icon: controller.isGroupedByDate.value 
            ? Icons.calendar_view_day_rounded 
            : Icons.calendar_view_day_outlined,
          subtitle: controller.isGroupedByDate.value ? "On" : "Off",
          onTap: () {
            Get.back();
            controller.onToggleGroupByDate(folder);
          },
        ),
        IOSMenuAction(
          label: "Delete Folder",
          icon: CupertinoIcons.delete,
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
