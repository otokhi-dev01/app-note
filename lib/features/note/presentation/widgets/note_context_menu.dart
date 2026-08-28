import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';

class NoteContextMenu extends StatelessWidget {
  final NoteController controller;

  final Widget Function(BuildContext context, VoidCallback toggleMenu)
  triggerBuilder;

  const NoteContextMenu({
    super.key,
    required this.controller,
    required this.triggerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => lg.GlassMenu(
        triggerBuilder: triggerBuilder,
        menuWidth: 250,
        menuAlignment: lg.GlassMenuAlignment.topRight,
        autoAdjustToScreen: true,
        menuPadding: const EdgeInsets.all(12),
        items: [
          _item(
            title: controller.viewMode.value == 'list'
                ? 'note_list_view_as_gallery'.tr
                : 'note_list_view_as_list'.tr,
            icon: controller.viewMode.value == 'list'
                ? Icons.grid_view_rounded
                : Icons.list_rounded,
            color: IosSemanticColors.purple,
            onTap: controller.toggleViewMode,
          ),
          _item(
            title: 'note_list_select_notes'.tr,
            icon: Icons.check_circle_outline,
            color: IosSemanticColors.blue,
            onTap: controller.toggleEditing,
          ),
          const lg.GlassMenuDivider(),
          _item(
            title: 'note_list_sort_by'.tr,
            icon: Icons.swap_vert_rounded,
            color: IosSemanticColors.orange,
            subtitle: controller.sortByName.value
                ? 'note_list_sort_name'.tr
                : 'note_list_sort_date_edited'.tr,
            onTap: controller.toggleSortByName,
          ),
          _item(
            title: 'note_list_group_by_date'.tr,
            icon: Icons.calendar_view_day_rounded,
            color: controller.isGroupedByDate.value
                ? IosSemanticColors.green
                : IosSemanticColors.gray,

            subtitle: controller.isGroupedByDate.value
                ? 'note_list_on'.tr
                : 'note_list_off'.tr,
            onTap: controller.toggleDateGrouping,
          ),
          const lg.GlassMenuDivider(),
          _item(
            title: 'note_list_view_attachments'.tr,
            icon: Icons.attach_file_rounded,
            color: IosSemanticColors.indigo,
            onTap: controller.viewAllAttachments,
          ),
        ],
      ),
    );
  }

  lg.GlassMenuItem _item({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return lg.GlassMenuItem(
      title: title,
      subtitle: subtitle,
      icon: Icon(icon, color: color),
      onTap: onTap,
    );
  }
}
