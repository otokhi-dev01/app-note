import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class FolderViewMenu extends StatelessWidget {
  final FolderController controller;

  const FolderViewMenu({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final mode = controller.viewMode.value;
      final isEditing = controller.isEditing.value;

      return lg.GlassMenu(
        menuWidth: 220,
        menuAlignment: lg.GlassMenuAlignment.topRight,
        autoAdjustToScreen: true,
        menuPadding: const EdgeInsets.all(12),
        triggerBuilder: (context, toggleMenu) => CustomGlassButton(
          onPressed: toggleMenu,
          semanticLabel: 'folder_view_menu'.tr,
          width: 44,
          height: 44,
          shape: GlassShape.circle,
          blur: 10,
          opacity: 0.15,
          thickness: 8,
          padding: EdgeInsets.zero,
          child: Icon(
            Icons.menu_rounded,
            color: theme.colorScheme.onSurface,
            size: 25,
          ),
        ),
        items: [
          lg.GlassMenuItem(
            title: isEditing ? 'done_action'.tr : 'folder_edit'.tr,
            icon: Icon(
              isEditing
                  ? CupertinoIcons.checkmark_circle_fill
                  : Icons.edit_note_rounded,
              color: isEditing
                  ? IosSemanticColors.green
                  : IosSemanticColors.orange,
            ),
            isSelected: isEditing,
            onTap: controller.toggleEditing,
          ),
          const lg.GlassMenuDivider(),
          _viewItem(
            title: 'folder_short_view'.tr,
            icon: Icons.view_agenda_outlined,
            selected: mode == 'short',
            onTap: () => controller.setViewMode('short'),
          ),
          const lg.GlassMenuDivider(),
          _viewItem(
            title: 'folder_list_view'.tr,
            icon: Icons.view_list_rounded,
            selected: mode == 'list',
            onTap: () => controller.setViewMode('list'),
          ),
        ],
      );
    });
  }

  lg.GlassMenuItem _viewItem({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return lg.GlassMenuItem(
      title: title,
      icon: Icon(icon, color: IosSemanticColors.blue),
      trailing: selected
          ? const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: IosSemanticColors.blue,
              size: 20,
            )
          : null,
      isSelected: selected,
      onTap: onTap,
    );
  }
}
