import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_create_modal.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';

/// A folder tile's context menu, iOS-26 style: a glass pull-down that morphs
/// open rather than raising a popup over the screen, matching
/// [NoteDetailMorePopup] and [NoteContextMenu].
///
/// Unlike those, this menu has no single button of its own — [FolderTile]
/// opens it from a long-press anywhere on the tile, from a tap on the tile
/// while editing, and from its own "..." icon. So instead of a
/// `triggerBuilder`, the tile drives it imperatively through [menuController]
/// via a zero-size trigger that morphs open from wherever it's placed.
class FolderContextMenu extends StatelessWidget {
  final Folder folder;
  final FolderController controller;
  final lg.GlassMenuController menuController;

  const FolderContextMenu({
    super.key,
    required this.folder,
    required this.controller,
    required this.menuController,
  });

  @override
  Widget build(BuildContext context) {
    // Group By Date's label reads a flag this menu itself flips, so it has
    // to be rebuilt rather than captured once.
    return Obx(
      () => lg.GlassMenu(
        controller: menuController,
        trigger: const SizedBox.shrink(),
        morphFromZero: true,
        menuWidth: 250,
        menuAlignment: lg.GlassMenuAlignment.topRight,
        autoAdjustToScreen: true,
        menuPadding: const EdgeInsets.all(12),
        items: [
          _item(
            title: 'folder_move'.tr,
            icon: CupertinoIcons.folder,
            onTap: () => controller.onMoveFolder(folder),
          ),
          _item(
            title: 'folder_rename'.tr,
            icon: Icons.edit_note_rounded,
            onTap: () => controller.onRenameFolder(folder),
          ),
          _item(
            title: 'folder_add'.tr,
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
          _item(
            title: 'folder_group_by_date'.tr,
            icon: controller.isGroupedByDate.value
                ? Icons.calendar_view_day_rounded
                : Icons.calendar_view_day_outlined,
            subtitle: controller.isGroupedByDate.value
                ? 'folder_status_on'.tr
                : 'folder_status_off'.tr,
            onTap: () => controller.onToggleGroupByDate(folder),
          ),
          _item(
            title: 'folder_delete'.tr,
            icon: CupertinoIcons.delete,
            isDestructive: true,
            onTap: () => controller.onDeleteFolder(folder),
          ),
          _item(
            title: 'folder_convert_smart'.tr,
            icon: Icons.auto_fix_high_rounded,
            onTap: () => controller.onConvertToSmartFolder(folder),
          ),
        ],
      ),
    );
  }

  lg.GlassMenuItem _item({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
    bool isDestructive = false,
  }) {
    return lg.GlassMenuItem(
      title: title,
      subtitle: subtitle,
      icon: Icon(icon),
      isDestructive: isDestructive,
      onTap: onTap,
    );
  }
}
