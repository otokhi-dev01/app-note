import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';

/// The attachment sheet's "Camera" entry is labelled
/// `note_editor_take_photo_video` ("Take Photo or Video"), but image_picker
/// only ever opens the camera in one fixed mode per call — there's no single
/// native call that lets the user choose between them once the camera is
/// open. This shows a small action sheet up front so the label's promise is
/// actually kept, then opens the camera in the chosen mode via
/// [NoteDetailController.addAttachment].
Future<void> showCameraCaptureSheet(
  BuildContext context,
  NoteDetailController controller,
) async {
  final isVideo = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: Text('note_editor_take_photo_video'.tr),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext, false),
          child: Text('note_editor_take_photo'.tr),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext, true),
          child: Text('note_editor_take_video'.tr),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(sheetContext),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
    ),
  );
  if (isVideo == null) return;

  await controller.addAttachment(ImageSource.camera, isVideo: isVideo);
}
