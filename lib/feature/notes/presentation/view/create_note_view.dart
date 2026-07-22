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
import '../widgets/common/note_navigation_back_button_widget.dart';
import '../widgets/common/note_navigation_icon_button_widget.dart';
import '../widgets/common/note_navigation_save_button_widget.dart';
part '../widgets/create_note/folder_status_widget.dart';
part '../widgets/create_note/main_editor_card_widget.dart';
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
part '../widgets/create_note/toolbar_button_widget.dart';
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
        leading: NoteNavigationBackButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Get.back<void>();
          },
        ),
        middle: Text(
          'New Note',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        trailing: Obx(() {
          final bool saving = controller.isSaving.value;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              NoteNavigationIconButton(
                icon: CupertinoIcons.ellipsis_circle,
                label: 'More options',
                onPressed: saving
                    ? null
                    : () {
                        _showMoreActions(context);
                      },
              ),
              NoteNavigationSaveButton(
                saving: saving,
                onPressed: saving
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        controller.createNote();
                      },
              ),
            ],
          );
        }),
      ),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: AppLiquidBackgroundWidget()),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 110, 16, 120),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _FolderStatus(
                          onPressed: () {
                            _showFolderPicker(context);
                          },
                        ),
    
                        const SizedBox(height: 12),
    
                        const _MainEditorCard(),
    
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

  Future<void> _showMoreActions(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('New Note'),
          message: const Text('Choose an action.'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _showFolderPicker(context);
              },
              child: const NoteActionSheetRow(
                icon: CupertinoIcons.folder,
                label: 'Choose Folder',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.addChecklistItem();
              },
              child: const NoteActionSheetRow(
                icon: CupertinoIcons.checkmark_square,
                label: 'Add Checklist Task',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _showMediaPicker(context);
              },
              child: const NoteActionSheetRow(
                icon: CupertinoIcons.paperclip,
                label: 'Add Attachment',
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
