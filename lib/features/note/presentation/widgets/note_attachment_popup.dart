import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/core/theme/ios_semantic_colors.dart';

class NoteAttachmentPopup extends StatelessWidget {
  final ValueChanged<String> onAction;
  final Widget trigger;

  const NoteAttachmentPopup({
    super.key,
    required this.onAction,
    required this.trigger,
  });

  @override
  Widget build(BuildContext context) {
    return lg.GlassMenu(
      trigger: trigger,
      menuWidth: 250,

      menuAlignment: lg.GlassMenuAlignment.bottomCenter,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      items: [
        _item(
          context,
          'note_editor_scan_text'.tr,
          CupertinoIcons.viewfinder,
          'scan_text',
        ),
        _item(
          context,
          'note_editor_scan_text_photo'.tr,
          CupertinoIcons.doc_text_viewfinder,
          'scan_text_photo',
        ),
        _item(
          context,
          'note_editor_scan_docs'.tr,
          CupertinoIcons.viewfinder_circle,
          'scan_docs',
        ),
        _item(
          context,
          'note_editor_scan_docs_photo'.tr,
          CupertinoIcons.doc_on_doc,
          'scan_docs_photo',
        ),
        _item(
          context,
          'note_editor_take_photo_video'.tr,
          CupertinoIcons.camera,
          'camera',
        ),
        _item(
          context,
          'note_editor_choose_photo_video'.tr,
          CupertinoIcons.photo_on_rectangle,
          'gallery',
        ),

        const lg.GlassMenuDivider(),
        _item(
          context,
          'note_editor_record_audio'.tr,
          CupertinoIcons.mic,
          'audio',
        ),
        _item(
          context,
          'note_editor_attach_file'.tr,
          CupertinoIcons.paperclip,
          'file',
        ),
      ],
    );
  }

  lg.GlassMenuItem _item(
    BuildContext context,
    String title,
    IconData icon,
    String type,
  ) {
    final color = switch (type) {
      'scan_text' || 'scan_text_photo' => IosSemanticColors.indigo,
      'scan_docs' || 'scan_docs_photo' => IosSemanticColors.purple,
      'camera' => IosSemanticColors.blue,
      'gallery' => IosSemanticColors.pink,
      'audio' => IosSemanticColors.red,
      _ => IosSemanticColors.orange,
    };
    return lg.GlassMenuItem(
      title: title,
      icon: Icon(icon, color: color),
      onTap: () => onAction(type),
    );
  }
}
