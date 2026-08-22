import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/features/note/presentation/controllers/note_controller.dart';

/// The note list's "more" menu, iOS-26 style: tapping the button morphs it
/// into a glass pull-down anchored where it was, the same way
/// [NoteAttachmentPopup] does for the editor's attachment button — rather
/// than raising a separate popup over the screen.
class NoteContextMenu extends StatelessWidget {
  final NoteController controller;

  /// Builds the button the menu grows out of, given the callback that opens
  /// it.
  ///
  /// A builder rather than the plain widget [NoteAttachmentPopup] takes: that
  /// trigger is a bare icon sitting inside the toolbar's own glass pill, while
  /// this one is a [CustomGlassButton] that brings its own glass and its own
  /// tap handling — and `GlassMenu.trigger` wraps whatever it's given in a
  /// second [GestureDetector], which would fight the button for the tap.
  final Widget Function(BuildContext context, VoidCallback toggleMenu)
  triggerBuilder;

  const NoteContextMenu({
    super.key,
    required this.controller,
    required this.triggerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Every label here reads a controller flag, and several of them flip as a
    // direct result of using this menu — without Obx the next open would show
    // the state from before the last one.
    return Obx(
      () => lg.GlassMenu(
        triggerBuilder: triggerBuilder,
        menuWidth: 250,
        // This trigger lives in the top-right of the app bar, so the menu's
        // top edge anchors to it and the body expands downward — the mirror
        // of NoteAttachmentPopup's `bottomCenter`, which has to grow upward to
        // stay clear of the keyboard.
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
            onTap: controller.toggleViewMode,
          ),
          _item(
            title: 'note_list_select_notes'.tr,
            icon: Icons.check_circle_outline,
            onTap: controller.toggleEditing,
          ),
          const lg.GlassMenuDivider(),
          _item(
            title: 'note_list_sort_by'.tr,
            icon: Icons.swap_vert_rounded,
            subtitle: controller.sortByName.value
                ? 'note_list_sort_name'.tr
                : 'note_list_sort_date_edited'.tr,
            onTap: controller.toggleSortByName,
          ),
          _item(
            title: 'note_list_group_by_date'.tr,
            icon: Icons.calendar_view_day_rounded,
            // Reads the flag the toggle actually writes. The old menu had
            // "Default (On)" hardcoded here, so it kept claiming grouping was
            // on after it had been switched off.
            subtitle: controller.isGroupedByDate.value
                ? 'note_list_on'.tr
                : 'note_list_off'.tr,
            onTap: controller.toggleDateGrouping,
          ),
          const lg.GlassMenuDivider(),
          _item(
            title: 'note_list_view_attachments'.tr,
            icon: Icons.attach_file_rounded,
            onTap: controller.viewAllAttachments,
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
  }) {
    return lg.GlassMenuItem(
      title: title,
      subtitle: subtitle,
      icon: Icon(icon),
      onTap: onTap,
    );
  }
}
