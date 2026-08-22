import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:Note/features/trash/presentation/controllers/recently_deleted_controller.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/core/theme/folder_appearance.dart';

/// A context menu for items in the Recently Deleted view, iOS-26 style:
/// long-pressing an item morphs it into a glass pull-down anchored at the
/// touch point, matching [NoteItemContextMenu].
class TrashItemContextMenu extends StatelessWidget {
  final Note? note;
  final Folder? folder;
  final RecentlyDeletedController controller;
  final Widget Function(BuildContext context, VoidCallback openMenu)
  triggerBuilder;

  const TrashItemContextMenu({
    super.key,
    this.note,
    this.folder,
    required this.controller,
    required this.triggerBuilder,
  }) : assert(note != null || folder != null);

  @override
  Widget build(BuildContext context) {
    final menuController = lg.GlassMenuController();

    return lg.GlassMenu(
      controller: menuController,
      menuWidth: 250,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      morphFromZero: true,
      triggerBuilder: (context, _) =>
          triggerBuilder(context, menuController.open),
      items: [
        _item(
          title: 'Restore',
          icon: CupertinoIcons.arrow_counterclockwise,
          onTap: () {
            if (note != null) {
              controller.recoverItem(noteId: note!.id);
            } else if (folder != null) {
              controller.recoverItem(folderId: folder!.id);
            }
          },
        ),
        if (controller.canDeletePermanently) ...[
          const lg.GlassMenuDivider(),
          _item(
            title: 'Delete Permanently',
            icon: CupertinoIcons.trash,
            onTap: () {
              if (note != null) {
                controller.deleteItemPermanently(
                  noteId: note!.id,
                  name: note!.title,
                );
              } else if (folder != null) {
                controller.deleteItemPermanently(
                  folderId: folder!.id,
                  name: folder!.displayName,
                );
              }
            },
            isDestructive: true,
          ),
        ],
      ],
    );
  }

  lg.GlassMenuItem _item({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return lg.GlassMenuItem(
      title: title,
      icon: Icon(icon),
      isDestructive: isDestructive,
      onTap: onTap,
    );
  }
}
