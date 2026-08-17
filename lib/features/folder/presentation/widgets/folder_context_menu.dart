import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:Note/shared/widgets/ios_action_menu.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_create_modal.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';

class FolderContextMenu extends StatelessWidget {
  final Folder folder;
  final FolderController controller;

  const FolderContextMenu({
    super.key,
    required this.folder,
    required this.controller,
  });

  static void show({
    required BuildContext context,
    required Folder folder,
    required FolderController controller,
  }) {
    IOSActionMenu.show(
      context: context,
      type: IOSMenuType.popup,
      actions: [
        IOSMenuAction(
          label: "Move Folder",
          icon: CupertinoIcons.folder,
          onTap: () => controller.onMoveFolder(folder),
        ),
        IOSMenuAction(
          label: "Rename Folder",
          icon: Icons.edit_note_rounded,
          onTap: () => controller.onRenameFolder(folder),
        ),
        IOSMenuAction(
          label: "Create Subfolder",
          icon: CupertinoIcons.folder_badge_plus,
          onTap: () {
            Get.to(
              () => FolderCreateModal(
                parentId: folder.id,
                controller: controller,
              ),
              fullscreenDialog: true,
              transition: Transition.cupertino,
            );
          },
        ),
        IOSMenuAction(
          label: "Group By Date",
          icon: controller.isGroupedByDate.value
              ? Icons.calendar_view_day_rounded
              : Icons.calendar_view_day_outlined,
          subtitle: controller.isGroupedByDate.value ? "On" : "Off",
          onTap: () => controller.onToggleGroupByDate(folder),
        ),
        IOSMenuAction(
          label: "Delete Folder",
          icon: CupertinoIcons.delete,
          isDestructive: true,
          onTap: () => controller.onDeleteFolder(folder),
        ),
        IOSMenuAction(
          label: "Convert to Smart Folder",
          icon: Icons.auto_fix_high_rounded,
          onTap: () => controller.onConvertToSmartFolder(folder),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
