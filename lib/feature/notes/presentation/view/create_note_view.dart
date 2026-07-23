import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/presentation/widgets/app_glass_surface.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../main/presentation/widgets/app_liquid_background_widget.dart';
import '../controllers/create_note_controller.dart';
import '../widgets/common/note_action_sheet_row_widget.dart';
part '../widgets/create_note/folder_status_widget.dart';
part '../widgets/create_note/title_field_widget.dart';
part '../widgets/create_note/body_field_widget.dart';
part '../widgets/create_note/checklist_section_widget.dart';
part '../widgets/create_note/checklist_row_widget.dart';
part '../widgets/create_note/error_message_widget.dart';
part '../widgets/create_note/selected_documents_section_widget.dart';
part '../widgets/create_note/document_row_widget.dart';
part '../widgets/create_note/selected_images_section_widget.dart';
part '../widgets/create_note/selected_image_tile_widget.dart';
part '../widgets/create_note/section_header_widget.dart';
part '../widgets/create_note/editor_toolbar_widget.dart';
part '../widgets/create_note/image_preview_page_widget.dart';
part '../widgets/create_note/preview_close_button_widget.dart';

class CreateNoteView extends GetView<CreateNoteController> {
  const CreateNoteView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        transitionBetweenRoutes: false,
        border: null,
        backgroundColor: Colors.transparent,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.xmark,
            color: theme.colorScheme.onSurface,
            size: 22,
          ),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Get.back<void>();
          },
        ),
        middle: Opacity(
          opacity: 0.6,
          child: Text(
            'Draft saved 2m ago',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        trailing: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minimumSize: Size.zero,
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          onPressed: () {
            HapticFeedback.mediumImpact();
            controller.createNote();
          },
          child: const Text(
            'Done',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: AppLiquidBackgroundWidget()),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showImageSourceDialog(context, controller);
            },
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 110, 20, 120),
              children: <Widget>[
                const _FolderStatus(),
                const SizedBox(height: 24),
                const _TitleField(),
                const SizedBox(height: 12),
                const _MetadataRow(),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 32),

                const _BodyField(),

                const _ErrorMessage(),

                const _ChecklistSection(),

                const _SelectedDocumentsSection(),

                _SelectedImagesSection(
                  onPreview: (NoteDraftImage image) {
                    _openImagePreview(context, image);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _EditorToolbar(
        onChecklist: () {
          FocusManager.instance.primaryFocus?.unfocus();
          controller.addChecklistItem();
        },
        onFolder: () {
          _showFolderPicker(context);
        },
        onCamera: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          await controller.takePhoto();
        },
        onPhotos: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          await controller.choosePhotos();
        },
        onAttachment: () {
          _showMediaPicker(context);
        },
      ),
    );
  }

  Future<void> _showFolderPicker(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final List<FolderEntity> folders = List<FolderEntity>.unmodifiable(
      controller.folders.toList(),
    );

    if (folders.isEmpty) {
      final dynamic result = await Get.toNamed(AppRoutes.createFolder);

      if (result == true) {
        await controller.loadFolders();
      }

      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return Obx(() {
          final int? selectedFolderId = controller.selectedFolderId.value;

          return CupertinoActionSheet(
            title: const Text('Choose Folder'),
            message: const Text('Choose where this note will be saved.'),
            actions: folders.map((FolderEntity folder) {
              final bool selected = selectedFolderId == folder.id;

              final String folderName = folder.name.trim().isEmpty
                  ? 'Unnamed Folder'
                  : folder.name.trim();

              return CupertinoActionSheetAction(
                isDefaultAction: selected,
                onPressed: () {
                  controller.selectFolder(folder.id);

                  Navigator.of(sheetContext).pop();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      selected
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.folder,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        folderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
              },
              child: const Text('Cancel'),
            ),
          );
        });
      },
    );
  }

  Future<void> _showMediaPicker(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Add Attachment'),
          message: const Text('Choose what you want to attach.'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                await controller.takePhoto();
              },
              child: const NoteActionSheetRow(
                icon: CupertinoIcons.camera,
                label: 'Take Photo',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                await controller.choosePhotos();
              },
              child: const NoteActionSheetRow(
                icon: CupertinoIcons.photo_on_rectangle,
                label: 'Choose Photos',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                await controller.chooseDocument();
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

  Future<void> _openImagePreview(
    BuildContext context,
    NoteDraftImage image,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return _ImagePreviewPage(image: image);
        },
      ),
    );
  }
}

Future<void> _showImageSourceDialog(
  BuildContext context,
  CreateNoteController controller,
) async {
  await showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return CupertinoAlertDialog(
        title: const Text('Add Image'),
        content: const Text('Take a photo or choose from your library.'),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await controller.takePhoto();
            },
            child: const Text('Take Photo'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await controller.choosePhotos();
            },
            child: const Text('Photo Library'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow();

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return Row(
      children: <Widget>[
        _MetadataItem(
          icon: CupertinoIcons.calendar,
          text: _formatDate(now),
        ),
        const SizedBox(width: 20),
        _MetadataItem(
          icon: CupertinoIcons.clock,
          text: _formatTime(now),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const List<String> months = <String>[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final int hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final String minute = date.minute.toString().padLeft(2, '0');
    final String amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetadataItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: colors.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
