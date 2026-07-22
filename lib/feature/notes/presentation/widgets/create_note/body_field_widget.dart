part of '../../view/create_note_view.dart';

class _BodyField extends GetView<CreateNoteController> {
  const _BodyField();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showiOSStyleImagePicker(context, controller);
      },
      child: CupertinoTextField(
        controller: controller.statementController,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        minLines: 14,
        maxLines: null,
        padding: EdgeInsets.zero,
        decoration: null,
        placeholder: 'Start writing your note...',
        placeholderStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.50),
          height: 1.55,
        ),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
          height: 1.55,
        ),
      ),
    );
  }
}

void _showiOSStyleImagePicker(
  BuildContext context,
  CreateNoteController controller,
) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext sheetContext) {
      return CupertinoActionSheet(
        title: const Text('Add Image'),
        message: const Text('Take a photo or choose from your library.'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await controller.takePhoto();
            },
            child: const NoteActionSheetRow(
              icon: CupertinoIcons.camera_fill,
              label: 'Take Photo',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await controller.choosePhotos();
            },
            child: const NoteActionSheetRow(
              icon: CupertinoIcons.photo_fill,
              label: 'Photo Library',
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(sheetContext).pop();
          },
          child: const Text('Cancel'),
        ),
      );
    },
  );
}
