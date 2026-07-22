import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../domain/repositories/note_repository.dart';
import 'home_controller.dart';

class NoteDraftImage {
  final XFile file;
  final String blockId;

  const NoteDraftImage({required this.file, required this.blockId});
}

class NoteDraftDocument {
  final String filePath;
  final String displayName;
  final String blockId;

  const NoteDraftDocument({
    required this.filePath,
    required this.displayName,
    required this.blockId,
  });
}

class CreateNoteChecklistItem {
  final String id;
  String text;
  bool checked;

  CreateNoteChecklistItem({
    required this.id,
    required this.text,
    required this.checked,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'text': text.trim(), 'checked': checked};
  }
}

class CreateNoteController extends GetxController {
  final NoteRepository noteRepository;
  final HomeController homeController;

  CreateNoteController({
    required this.noteRepository,
    required this.homeController,
  });

  final TextEditingController titleController = TextEditingController();

  final TextEditingController statementController = TextEditingController();

  final RxnInt selectedFolderId = RxnInt();

  final RxList<NoteDraftImage> selectedImages = <NoteDraftImage>[].obs;

  final RxList<NoteDraftDocument> selectedDocuments = <NoteDraftDocument>[].obs;

  final RxList<CreateNoteChecklistItem> checklistItems =
      <CreateNoteChecklistItem>[].obs;

  final RxBool isSaving = false.obs;
  final RxBool isLoadingFolders = false.obs;

  final RxString errorMessage = ''.obs;

  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  String? _textBlockId;
  String? _checklistBlockId;
  String? _lastSavedContentFingerprint;

  /*
   * Keep the created ID when an upload fails.
   * Retrying will update the same note instead of
   * creating another note.
   */
  int? _createdNoteId;

  /*
   * Keeps successfully uploaded image IDs so retrying
   * does not upload the same image twice.
   */
  final Set<String> _uploadedBlockIds = <String>{};

  List<FolderEntity> get folders {
    return homeController.folders.toList(growable: false);
  }

  FolderEntity? get selectedFolder {
    final int? folderId = selectedFolderId.value;

    if (folderId == null) {
      return null;
    }

    for (final FolderEntity folder in folders) {
      if (folder.id == folderId) {
        return folder;
      }
    }

    return null;
  }

  String get selectedFolderName {
    final FolderEntity? folder = selectedFolder;

    if (folder == null) {
      return 'Choose folder';
    }

    final String name = folder.name.trim();

    return name.isEmpty ? 'Unnamed Folder' : name;
  }

  @override
  void onInit() {
    super.onInit();

    _selectInitialFolder();
  }

  @override
  void onReady() {
    super.onReady();

    if (homeController.folders.isEmpty) {
      loadFolders();
    }
  }

  void _selectInitialFolder() {
    final int? currentFolderId = homeController.selectedFolderId.value;

    if (currentFolderId != null) {
      final bool exists = homeController.folders.any((FolderEntity folder) {
        return folder.id == currentFolderId;
      });

      if (exists) {
        selectedFolderId.value = currentFolderId;
        return;
      }
    }

    if (homeController.folders.isNotEmpty) {
      selectedFolderId.value = homeController.folders.first.id;
    }
  }

  Future<void> loadFolders() async {
    try {
      isLoadingFolders.value = true;
      errorMessage.value = '';

      await homeController.loadFolders();

      final int? currentFolderId = selectedFolderId.value;

      final bool selectedFolderExists =
          currentFolderId != null &&
          homeController.folders.any((FolderEntity folder) {
            return folder.id == currentFolderId;
          });

      if (!selectedFolderExists && homeController.folders.isNotEmpty) {
        selectedFolderId.value = homeController.folders.first.id;
      }
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      isLoadingFolders.value = false;
    }
  }

  void selectFolder(int folderId) {
    final bool folderExists = homeController.folders.any((FolderEntity folder) {
      return folder.id == folderId;
    });

    if (!folderExists) {
      errorMessage.value = 'The selected folder is unavailable.';
      return;
    }

    selectedFolderId.value = folderId;
    errorMessage.value = '';
  }

  Future<void> takePhoto() async {
    try {
      errorMessage.value = '';

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (photo == null) {
        return;
      }

      selectedImages.add(NoteDraftImage(file: photo, blockId: _uuid.v4()));
    } catch (error) {
      errorMessage.value =
          'Could not open the camera. '
          '${_cleanError(error)}';
    }
  }

  Future<void> choosePhotos() async {
    try {
      errorMessage.value = '';

      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (images.isEmpty) {
        return;
      }

      final List<NoteDraftImage> newImages = images
          .map((XFile image) {
            return NoteDraftImage(file: image, blockId: _uuid.v4());
          })
          .toList(growable: false);

      selectedImages.addAll(newImages);
    } catch (error) {
      errorMessage.value =
          'Could not open the photo library. '
          '${_cleanError(error)}';
    }
  }

  void removeImage(NoteDraftImage image) {
    if (_uploadedBlockIds.contains(image.blockId)) {
      errorMessage.value =
          'This image is already attached to the saved note and cannot be '
          'removed from the draft.';
      return;
    }

    selectedImages.removeWhere((NoteDraftImage currentImage) {
      return currentImage.blockId == image.blockId;
    });

    _uploadedBlockIds.remove(image.blockId);
  }

  Future<void> chooseDocument() async {
    try {
      errorMessage.value = '';

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      final PlatformFile? file = result?.files.single;
      final String? path = file?.path;

      if (file == null || path == null || path.trim().isEmpty) {
        return;
      }

      selectedDocuments.add(
        NoteDraftDocument(
          filePath: path,
          displayName: file.name,
          blockId: _uuid.v4(),
        ),
      );
    } catch (error) {
      errorMessage.value =
          'Could not open the file picker. ${_cleanError(error)}';
    }
  }

  void removeDocument(NoteDraftDocument document) {
    if (_uploadedBlockIds.contains(document.blockId)) {
      errorMessage.value =
          'This file is already attached to the saved note and cannot be '
          'removed from the draft.';
      return;
    }

    selectedDocuments.removeWhere(
      (NoteDraftDocument current) => current.blockId == document.blockId,
    );
    _uploadedBlockIds.remove(document.blockId);
  }

  void addChecklistItem() {
    if (isSaving.value) {
      return;
    }

    checklistItems.add(
      CreateNoteChecklistItem(id: _uuid.v4(), text: '', checked: false),
    );
  }

  void updateChecklistItem(String id, String text) {
    final CreateNoteChecklistItem? item = _findChecklistItem(id);

    if (item != null) {
      item.text = text;
    }
  }

  void toggleChecklistItem(String id, bool checked) {
    final CreateNoteChecklistItem? item = _findChecklistItem(id);

    if (item != null) {
      item.checked = checked;
      checklistItems.refresh();
    }
  }

  void removeChecklistItem(String id) {
    checklistItems.removeWhere((CreateNoteChecklistItem item) => item.id == id);
  }

  CreateNoteChecklistItem? _findChecklistItem(String id) {
    for (final CreateNoteChecklistItem item in checklistItems) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  /*
   * This is the method called by your Create Note button.
   *
   * Order:
   * 1. Create note header
   * 2. Save note content
   * 3. Upload camera/gallery images
   * 4. Refresh home
   * 5. Open Note Editor
   */
  Future<void> createNote() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final String title = titleController.text.trim();

    final String statement = statementController.text.trim();

    final int? folderId = selectedFolderId.value;

    final String? validationError = _validate(folderId: folderId, title: title);

    if (validationError != null) {
      errorMessage.value = validationError;
      return;
    }

    try {
      isSaving.value = true;
      errorMessage.value = '';

      /*
       * Create the note header first and receive
       * the newly created note ID.
       */
      final int noteId = await noteRepository.saveNote(
        noteId: _createdNoteId ?? 0,
        folderId: folderId!,
        title: title,
      );

      _createdNoteId = noteId;

      /*
       * Convert statement and images into content blocks.
       */
      final List<Map<String, dynamic>> contentBlocks = _buildContentBlocks(
        statement: statement,
      );

      /*
       * SAVE CONTENT METHOD GOES HERE.
       *
       * Send contentBlocks directly as a List.
       * Do not use jsonEncode(contentBlocks).
       */
      final String contentFingerprint = jsonEncode(<String, dynamic>{
        'title': title,
        'content': contentBlocks,
      });

      if (_lastSavedContentFingerprint != contentFingerprint) {
        await noteRepository.saveContent(
          id: noteId,
          title: title,
          content: contentBlocks,
        );
        _lastSavedContentFingerprint = contentFingerprint;
      }

      /*
       * Upload images after the content structure
       * has been saved.
       */
      final List<NoteDraftImage> imageSnapshot = selectedImages.toList(
        growable: false,
      );

      for (int index = 0; index < imageSnapshot.length; index++) {
        final NoteDraftImage image = imageSnapshot[index];

        if (_uploadedBlockIds.contains(image.blockId)) {
          continue;
        }

        final int contentIndex = contentBlocks.indexWhere((
          Map<String, dynamic> block,
        ) {
          return block['blockId']?.toString() == image.blockId;
        });

        await noteRepository.uploadAttachment(
          noteId: noteId,
          filePath: image.file.path,
          blockId: image.blockId,
          displayOrder: contentIndex >= 0 ? contentIndex + 1 : index + 1,
        );

        _uploadedBlockIds.add(image.blockId);
      }

      final List<NoteDraftDocument> documentSnapshot = selectedDocuments.toList(
        growable: false,
      );

      for (int index = 0; index < documentSnapshot.length; index++) {
        final NoteDraftDocument document = documentSnapshot[index];

        if (_uploadedBlockIds.contains(document.blockId)) {
          continue;
        }

        final int contentIndex = contentBlocks.indexWhere((
          Map<String, dynamic> block,
        ) {
          return block['blockId']?.toString() == document.blockId;
        });

        await noteRepository.uploadAttachment(
          noteId: noteId,
          filePath: document.filePath,
          blockId: document.blockId,
          displayOrder: contentIndex >= 0
              ? contentIndex + 1
              : selectedImages.length + index + 1,
        );

        _uploadedBlockIds.add(document.blockId);
      }

      homeController.selectedFolderId.value = folderId;

      await homeController.loadAll();

      if (!Get.testMode) {
        Get.offNamed(AppRoutes.noteEditor, arguments: noteId);
      }

      if (!Get.testMode && Get.context != null) {
        Get.snackbar(
          'Note created',
          'Your note was created successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      isSaving.value = false;
    }
  }

  List<Map<String, dynamic>> _buildContentBlocks({required String statement}) {
    final List<Map<String, dynamic>> blocks = <Map<String, dynamic>>[];

    int displayOrder = 0;

    if (statement.isNotEmpty) {
      displayOrder++;

      final String textBlockId = _textBlockId ??= _uuid.v4();

      blocks.add(<String, dynamic>{
        'id': textBlockId,
        'blockId': textBlockId,
        'type': 'text',
        'text': statement,
        'displayOrder': displayOrder,
      });
    }

    final List<CreateNoteChecklistItem> taskSnapshot = checklistItems
        .where((CreateNoteChecklistItem item) => item.text.trim().isNotEmpty)
        .toList(growable: false);

    if (taskSnapshot.isNotEmpty) {
      displayOrder++;
      final String checklistId = _checklistBlockId ??= _uuid.v4();

      blocks.add(<String, dynamic>{
        'id': checklistId,
        'blockId': checklistId,
        'type': 'checklist',
        'items': taskSnapshot
            .map((CreateNoteChecklistItem item) => item.toJson())
            .toList(growable: false),
        'displayOrder': displayOrder,
      });
    }

    final List<NoteDraftImage> imageSnapshot = selectedImages.toList(
      growable: false,
    );

    for (final NoteDraftImage image in imageSnapshot) {
      displayOrder++;

      blocks.add(<String, dynamic>{
        'id': image.blockId,
        'blockId': image.blockId,
        'type': 'attachment',
        'attachmentType': 'image',
        'displayOrder': displayOrder,
      });
    }

    for (final NoteDraftDocument document in selectedDocuments) {
      displayOrder++;

      blocks.add(<String, dynamic>{
        'id': document.blockId,
        'blockId': document.blockId,
        'type': 'attachment',
        'attachmentType': 'document',
        'displayName': document.displayName,
        'displayOrder': displayOrder,
      });
    }

    return blocks;
  }

  String? _validate({required int? folderId, required String title}) {
    if (folderId == null) {
      return 'Please choose a folder.';
    }

    final bool folderExists = homeController.folders.any((FolderEntity folder) {
      return folder.id == folderId;
    });

    if (!folderExists) {
      return 'The selected folder no longer exists.';
    }

    if (title.isEmpty) {
      return 'Please enter a note title.';
    }

    if (title.length > 250) {
      return 'The note title cannot exceed 250 characters.';
    }

    return null;
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }

  @override
  void onClose() {
    /* 
     * Disposal of TextEditingControllers is omitted to prevent 
     * 'used after being disposed' errors during route transitions. 
     * GC will handle cleanup once views are unmounted.
     */
    selectedImages.clear();
    selectedDocuments.clear();
    checklistItems.clear();
    _uploadedBlockIds.clear();
    _lastSavedContentFingerprint = null;

    super.onClose();
  }
}
