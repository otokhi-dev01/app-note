import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/presentation/widgets/app_surface_card.dart';
import '../controllers/note_editor_controller.dart';

import '../widgets/common/note_action_sheet_row_widget.dart';
import '../widgets/common/note_navigation_back_button_widget.dart';
import '../widgets/common/note_navigation_icon_button_widget.dart';
import '../widgets/common/note_navigation_save_button_widget.dart';
part '../widgets/note_editor/note_editor_content_widget.dart';
part '../widgets/note_editor/note_metadata_card_widget.dart';
part '../widgets/note_editor/locked_note_banner_widget.dart';
part '../widgets/note_editor/note_text_section_widget.dart';
part '../widgets/note_editor/inline_error_banner_widget.dart';
part '../widgets/note_editor/checklist_card_widget.dart';
part '../widgets/note_editor/checklist_row_widget.dart';
part '../widgets/note_editor/attachments_card_widget.dart';
part '../widgets/note_editor/attachment_row_widget.dart';
part '../widgets/note_editor/section_title_row_widget.dart';
part '../widgets/note_editor/small_icon_surface_widget.dart';
part '../widgets/note_editor/bottom_save_button_widget.dart';
part '../widgets/note_editor/note_loading_state_widget.dart';
part '../widgets/note_editor/note_editor_error_state_widget.dart';

class NoteEditorView extends GetView<NoteEditorController> {
  const NoteEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color pageColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: pageColor,
      appBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        transitionBetweenRoutes: false,
        border: null,
        backgroundColor: pageColor.withValues(alpha: 0.94),
        leading: NoteNavigationBackButton(onPressed: Get.back),
        middle: Text(
          'Edit Note',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Obx(() {
          final bool unavailable =
              controller.isSaving.value ||
              controller.isLoading.value ||
              !controller.hasLoadedNote;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              NoteNavigationIconButton.editor(
                label: 'Note options',
                icon: CupertinoIcons.ellipsis_circle,
                onPressed: unavailable
                    ? null
                    : () {
                        _showStateOptions(context);
                      },
              ),
              const SizedBox(width: 2),
              NoteNavigationSaveButton.editor(
                saving: controller.isSaving.value,
                enabled:
                    controller.canEdit &&
                    !controller.isLoading.value &&
                    !controller.isSaving.value,
                onPressed: controller.saveChanges,
              ),
            ],
          );
        }),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Obx(() => _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value) {
      return const _NoteLoadingState();
    }

    final String error = controller.errorMessage.value.trim();

    if (error.isNotEmpty && controller.note.value == null) {
      return _NoteEditorErrorState(
        message: error,
        onRetry: controller.reloadNote,
      );
    }

    return _NoteEditorContent(
      controller: controller,
      onAddAttachment: () {
        _showAttachmentOptions(context);
      },
    );
  }

  Future<void> _showAttachmentOptions(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Add Attachment'),
          message: const Text('Choose what you want to attach.'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _pickAndUploadImage(source: ImageSource.camera);
              },
              child: const NoteActionSheetRow(
                icon: CupertinoIcons.camera,
                label: 'Take Photo',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _pickAndUploadImage(source: ImageSource.gallery);
              },
              child: const NoteActionSheetRow(
                icon: CupertinoIcons.photo,
                label: 'Choose Photo',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _pickAndUploadDocument();
              },
              child: const NoteActionSheetRow(
                icon: CupertinoIcons.doc,
                label: 'Choose Document',
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

  Future<void> _pickAndUploadImage({required ImageSource source}) async {
    if (!controller.canEdit) {
      return;
    }

    try {
      final ImagePicker imagePicker = ImagePicker();

      final XFile? selectedImage = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (selectedImage == null) {
        return;
      }

      await controller.uploadAttachment(filePath: selectedImage.path);
    } catch (error) {
      controller.errorMessage.value = _cleanError(error);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    if (!controller.canEdit) {
      return;
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      final String? path = result?.files.single.path;

      if (path == null || path.trim().isEmpty) {
        return;
      }

      await controller.uploadAttachment(filePath: path);
    } catch (error) {
      controller.errorMessage.value = _cleanError(error);
    }
  }

  Future<void> _showStateOptions(BuildContext context) async {
    final currentNote = controller.note.value;

    if (currentNote == null) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Note Options'),
          message: const Text('Manage this note.'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.togglePin();
              },
              child: NoteActionSheetRow(
                icon: currentNote.isPinned
                    ? CupertinoIcons.pin_slash
                    : CupertinoIcons.pin,
                label: currentNote.isPinned ? 'Unpin Note' : 'Pin Note',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.toggleArchive();
              },
              child: NoteActionSheetRow(
                icon: CupertinoIcons.archivebox,
                label: currentNote.isArchived
                    ? 'Move to Notes'
                    : 'Move to Archive',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.toggleLock();
              },
              child: NoteActionSheetRow(
                icon: currentNote.isLocked
                    ? CupertinoIcons.lock_open
                    : CupertinoIcons.lock,
                label: currentNote.isLocked ? 'Unlock Note' : 'Lock Note',
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

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }
}

String _friendlyDate(DateTime date) {
  final DateTime now = DateTime.now();

  final DateTime today = DateTime(now.year, now.month, now.day);

  final DateTime target = DateTime(date.year, date.month, date.day);

  final int difference = today.difference(target).inDays;

  if (difference == 0) {
    return 'Today';
  }

  if (difference == 1) {
    return 'Yesterday';
  }

  if (difference > 1 && difference < 7) {
    return '${difference}d ago';
  }

  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} '
      '${date.day}';
}
