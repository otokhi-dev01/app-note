import 'package:flutter/cupertino.dart';
import '../../../widgets/glass_widgets.dart';

class NoteAttachmentPopup extends StatelessWidget {
  final Function(String type) onAction;

  const NoteAttachmentPopup({super.key, required this.onAction});

  static Future<void> show({
    required BuildContext context,
    required Function(String type) onAction,
  }) {
    return CustomGlassActionSheet.show(
      context: context,
      actions: [
        CustomGlassActionSheetAction(
          label: 'Scan Text',
          icon: CupertinoIcons.viewfinder,
          onPressed: () => onAction('scan_text'),
        ),
        CustomGlassActionSheetAction(
          label: 'Scan Documents',
          icon: CupertinoIcons.viewfinder_circle,
          onPressed: () => onAction('scan_docs'),
        ),
        CustomGlassActionSheetAction(
          label: 'Take Photo or Video',
          icon: CupertinoIcons.camera,
          onPressed: () => onAction('camera'),
        ),
        CustomGlassActionSheetAction(
          label: 'Choose Photo or Video',
          icon: CupertinoIcons.photo_on_rectangle,
          onPressed: () => onAction('gallery'),
        ),
        CustomGlassActionSheetAction(
          label: 'Drawing',
          icon: CupertinoIcons.pencil_outline,
          onPressed: () => onAction('drawing'),
        ),
        CustomGlassActionSheetAction(
          label: 'Record Audio',
          icon: CupertinoIcons.mic,
          onPressed: () => onAction('audio'),
        ),
        CustomGlassActionSheetAction(
          label: 'Attach File',
          icon: CupertinoIcons.paperclip,
          onPressed: () => onAction('file'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
