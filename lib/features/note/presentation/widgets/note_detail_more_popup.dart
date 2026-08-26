import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';

class NoteDetailMorePopup extends StatelessWidget {
  final NoteDetailController controller;

  final Widget Function(BuildContext context, VoidCallback toggleMenu)
  triggerBuilder;

  const NoteDetailMorePopup({
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
            title: controller.isPinned.value
                ? 'note_editor_unpin'.tr
                : 'note_editor_pin'.tr,
            icon: controller.isPinned.value
                ? CupertinoIcons.pin_slash
                : CupertinoIcons.pin,
            color: IosSemanticColors.orange,
            onTap: controller.togglePin,
          ),
          _item(
            title: controller.isArchived.value
                ? 'note_editor_unarchive'.tr
                : 'note_editor_archive'.tr,
            icon: controller.isArchived.value
                ? CupertinoIcons.archivebox_fill
                : CupertinoIcons.archivebox,
            color: IosSemanticColors.indigo,
            onTap: controller.toggleArchive,
          ),
          _item(
            title: controller.isLocked.value
                ? 'note_editor_unlock'.tr
                : 'note_editor_lock'.tr,
            icon: controller.isLocked.value
                ? CupertinoIcons.lock_fill
                : CupertinoIcons.lock,
            color: controller.isLocked.value
                ? IosSemanticColors.red
                : IosSemanticColors.green,
            onTap: controller.toggleLock,
          ),
          const lg.GlassMenuDivider(),
          _item(
            title: 'note_editor_move'.tr,
            icon: CupertinoIcons.folder,
            color: IosSemanticColors.blue,
            onTap: controller.moveNote,
          ),
          _item(
            title: 'note_editor_find_in_note'.tr,
            icon: CupertinoIcons.doc_text_search,
            color: IosSemanticColors.orange,
            onTap: controller.toggleSearch,
          ),
          _item(
            title: 'note_editor_export_pdf'.tr,
            icon: CupertinoIcons.doc_richtext,
            color: IosSemanticColors.red,
            onTap: controller.exportNoteToPdf,
          ),
          const lg.GlassMenuDivider(),
          _item(
            title: 'note_editor_delete'.tr,
            icon: CupertinoIcons.trash,
            color: IosSemanticColors.red,
            onTap: controller.deleteNote,
            isDestructive: true,
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
