import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/core/theme/ios_semantic_colors.dart';

/// The toolbar's attachment button, iOS-26 style: tapping it morphs the
/// button itself into a glass pull-down menu anchored right where it was
/// (matching the system's own "+" menu in Notes), instead of raising a
/// full-width bottom action sheet.
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
      // The attachment button lives in the toolbar sitting right above the
      // keyboard, so the menu must grow upward from it — opening downward
      // (the auto-detected default) would put it underneath the keyboard,
      // which is a native layer that always draws on top of Flutter's own
      // content and would hide it. `bottomCenter` anchors the menu's
      // bottom edge to the trigger so the body expands up instead.
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
          'note_editor_scan_docs'.tr,
          CupertinoIcons.viewfinder_circle,
          'scan_docs',
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

        // _item(context, 'Drawing', CupertinoIcons.pencil_outline, 'drawing'),
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
      'scan_text' => IosSemanticColors.indigo,
      'scan_docs' => IosSemanticColors.purple,
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
