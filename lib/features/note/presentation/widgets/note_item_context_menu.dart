import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:Note/core/feedback/app_dialogs.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';

/// A context menu for an individual note item (in grid or list), iOS-26 style:
/// long-pressing the note morphs it into a glass pull-down anchored at the
/// touch point, matching [NoteContextMenu].
class NoteItemContextMenu extends StatelessWidget {
  final Note note;
  final int folderId;
  final NoteController controller;
  final Widget Function(BuildContext context, VoidCallback openMenu)
  triggerBuilder;

  const NoteItemContextMenu({
    super.key,
    required this.note,
    required this.folderId,
    required this.controller,
    required this.triggerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final menuController = lg.GlassMenuController();

    return lg.GlassMenu(
      controller: menuController,
      menuWidth: 250,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      // Morphing from zero makes the menu "bloom" from the touch point rather
      // than appearing as a large pre-formed glass slab.
      morphFromZero: true,
      triggerBuilder: (context, _) =>
          triggerBuilder(context, menuController.open),
      items: [
        _item(
          title: note.isPinned ? 'note_list_unpin'.tr : 'note_list_pin'.tr,
          icon: note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
          color: IosSemanticColors.orange,
          onTap: () async {
            await controller.updateNoteState(note.id, isPinned: !note.isPinned);
            await controller.fetchNotes(folderId: folderId, refresh: true);
          },
        ),
        _item(
          title: 'note_list_move'.tr,
          icon: CupertinoIcons.folder_badge_plus,
          color: IosSemanticColors.blue,
          onTap: () {
            controller.selectOnly(note.id);
            controller.moveSelectedNotes(context, folderId);
          },
        ),
        const lg.GlassMenuDivider(),
        _item(
          title: 'note_list_delete'.tr,
          icon: CupertinoIcons.trash,
          color: IosSemanticColors.red,
          onTap: () async {
            if (await AppDialogs.confirmDeleteNotes(1)) {
              controller.selectOnly(note.id);
              await controller.deleteSelectedNotes(folderId);
            }
          },
          isDestructive: true,
        ),
      ],
    );
  }

  lg.GlassMenuItem _item({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return lg.GlassMenuItem(
      title: title,
      icon: Icon(icon, color: color),
      isDestructive: isDestructive,
      onTap: onTap,
    );
  }
}
