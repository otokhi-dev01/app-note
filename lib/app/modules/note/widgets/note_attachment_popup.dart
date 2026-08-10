import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../widgets/ios_action_menu.dart';

class NoteAttachmentPopup extends StatelessWidget {
  final Function(String type) onAction;

  const NoteAttachmentPopup({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final color = Get.theme.primaryColor;
    
    return IOSActionMenu(
      type: IOSMenuType.bottomSheet,
      actions: [
        IOSMenuAction(
          label: 'Scan Text',
          icon: CupertinoIcons.viewfinder,
          color: color,
          onTap: () => onAction('scan_text'),
        ),
        IOSMenuAction(
          label: 'Scan Documents',
          icon: CupertinoIcons.viewfinder_circle,
          color: color,
          onTap: () => onAction('scan_docs'),
        ),
        IOSMenuAction(
          label: 'Take Photo or Video',
          icon: CupertinoIcons.camera,
          color: color,
          onTap: () => onAction('camera'),
        ),
        IOSMenuAction(
          label: 'Choose Photo or Video',
          icon: CupertinoIcons.photo_on_rectangle,
          color: color,
          onTap: () => onAction('gallery'),
        ),
        IOSMenuAction(
          label: 'Record Audio',
          icon: CupertinoIcons.mic,
          color: color,
          onTap: () => onAction('audio'),
        ),
        IOSMenuAction(
          label: 'Attach File',
          icon: CupertinoIcons.paperclip,
          color: color,
          onTap: () => onAction('file'),
        ),
      ],
    );
  }
}
