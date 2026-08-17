import 'package:flutter/material.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';

import 'package:Note/shared/widgets/ios_action_menu.dart';

class NoteContextMenu extends StatelessWidget {
  final NoteController controller;

  const NoteContextMenu({super.key, required this.controller});

  static void show({
    required BuildContext context,
    required NoteController controller,
  }) {
    IOSActionMenu.show(
      context: context,
      type: IOSMenuType.popup,
      actions: [
        IOSMenuAction(
          label: controller.viewMode.value == "list"
              ? "View as Gallery"
              : "View as List",
          icon: controller.viewMode.value == "list"
              ? Icons.grid_view_rounded
              : Icons.list_rounded,
          onTap: () => controller.toggleViewMode(),
        ),
        IOSMenuAction(
          label: "Select Notes",
          icon: Icons.check_circle_outline,
          onTap: () => controller.toggleEditing(),
        ),
        IOSMenuAction(
          label: "Sort By",
          icon: Icons.swap_vert_rounded,
          subtitle: "Default (Date Edited)",
          onTap: () => controller.updateSorting("Date Edited"),
        ),
        IOSMenuAction(
          label: "Group By Date",
          icon: Icons.calendar_view_day_rounded,
          subtitle: "Default (On)",
          onTap: () => controller.toggleDateGrouping(),
        ),
        IOSMenuAction(
          label: "View Attachments",
          icon: Icons.attach_file_rounded,
          onTap: () => controller.viewAllAttachments(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
