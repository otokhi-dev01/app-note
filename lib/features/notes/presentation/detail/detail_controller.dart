import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/app/navigation/route_contracts.dart';
import 'package:notes/core/presentation/images/image_picker_feedback.dart';
import 'package:notes/core/presentation/images/note_image_picker.dart';
import 'package:notes/features/notes/domain/entities/note.dart';
import 'package:notes/features/notes/domain/repositories/attachment_file_repository.dart';
import 'package:notes/features/notes/domain/usecases/get_note_usecase.dart';
import 'package:notes/features/notes/domain/usecases/update_note_usecase.dart';

import '../home/widgets/home_sheets.dart';
import 'image_editor_view.dart';

class DetailController extends GetxController {
  DetailController(
    this._getNoteUseCase,
    this._updateNoteUseCase, {
    AttachmentFileRepository? attachmentFiles,
    NoteImagePicker? imagePicker,
  }) : _attachmentFiles = attachmentFiles,
       _imagePicker = imagePicker ?? SystemNoteImagePicker();

  final GetNoteUseCase _getNoteUseCase;
  final UpdateNoteUseCase _updateNoteUseCase;
  final AttachmentFileRepository? _attachmentFiles;
  final NoteImagePicker _imagePicker;

  final note = Rxn<Note>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  int? get noteId {
    return NoteDetailArguments.noteIdFrom(Get.arguments);
  }

  @override
  void onInit() {
    super.onInit();
    loadNote();
  }

  Future<void> loadNote() async {
    final id = noteId;
    if (id == null) {
      errorMessage.value = 'Invalid note ID.';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      final result = await _getNoteUseCase(id);

      if (result != null) {
        note.value = result;
      } else {
        note.value = null;
        errorMessage.value = 'Note not found.';
      }
    } catch (error) {
      note.value = null;
      errorMessage.value = 'Failed to load note. ${_readableError(error)}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> edit() async {
    final currentNote = note.value;
    if (currentNote == null) return;

    final result = await Get.toNamed(AppRoutes.editor, arguments: currentNote);

    if (result == EditorResult.deleted) {
      Get.back(result: true);
    } else if (result == EditorResult.saved) {
      await loadNote();
    }
  }

  Future<void> delete() async {
    final currentNote = note.value;
    if (currentNote == null) return;

    Get.dialog(
      CupertinoAlertDialog(
        title: const Text('Move to Trash?'),
        content: const Text('This note will be moved to Recently Deleted.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Get.back(); // Close dialog

              try {
                final updatedNote = currentNote.copyWith(
                  isDeleted: true,
                  deletedAt: DateTime.now(),
                );

                await _updateNoteUseCase(updatedNote);

                // Go back to home first
                Get.back(result: true);

                // Show snackbar after navigation
                Get.snackbar(
                  'Moved to Trash',
                  'Note moved to Recently Deleted.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Get.theme.colorScheme.primary,
                  colorText: Get.theme.colorScheme.onPrimary,
                  icon: Icon(
                    CupertinoIcons.trash,
                    color: Get.theme.colorScheme.onPrimary,
                  ),
                  borderRadius: 15,
                  margin: const EdgeInsets.all(15),
                  duration: const Duration(seconds: 2),
                );
              } catch (e) {
                _showError('Failed to delete note. ${_readableError(e)}');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> addImage(ImageSource source) async {
    XFile? image;
    try {
      image = await _imagePicker.pickImage(source: source, imageQuality: 90);
    } on PlatformException catch (error) {
      final usePhotoLibrary = await ImagePickerFeedback.show(
        error,
        source: source,
      );
      if (usePhotoLibrary && source == ImageSource.camera) {
        await addImage(ImageSource.gallery);
      }
      return;
    } catch (_) {
      _showError('The image picker could not be opened. Please try again.');
      return;
    }

    if (image != null) {
      String? copiedPath;
      try {
        final filePath = await _attachmentRepository.importImage(image.path);
        copiedPath = filePath;

        final currentNote = note.value;
        if (currentNote != null) {
          final updatedNote = currentNote.copyWith(
            imagePaths: [...currentNote.imagePaths, filePath],
            imageAnchors: [
              ...currentNote.imageAnchors,
              currentNote.content.split('\n').length - 1,
            ],
            updatedAt: DateTime.now(),
          );
          await _updateNoteUseCase(updatedNote);
          note.value = updatedNote;
        } else {
          await _deleteFile(filePath);
        }
      } catch (e) {
        if (copiedPath != null) await _deleteFile(copiedPath);
        _showError('Failed to add the attachment. ${_readableError(e)}');
      }
    }
  }

  Future<void> editImage(String imagePath, int index) async {
    final editedPath = await Get.to<String>(
      () => ImageEditorView(imagePath: imagePath),
    );

    if (editedPath != null) {
      final currentNote = note.value;
      if (currentNote != null) {
        try {
          final newPaths = List<String>.from(currentNote.imagePaths);
          newPaths[index] = editedPath;
          final updatedNote = currentNote.copyWith(
            imagePaths: newPaths,
            updatedAt: DateTime.now(),
          );
          await _updateNoteUseCase(updatedNote);
          note.value = updatedNote;
          if (editedPath != imagePath) await _deleteFile(imagePath);
        } catch (error) {
          if (editedPath != imagePath) await _deleteFile(editedPath);
          _showError(
            'Failed to save the edited image. ${_readableError(error)}',
          );
        }
      }
    }
  }

  Future<void> removeImage(int index) async {
    final currentNote = note.value;
    if (currentNote != null &&
        index >= 0 &&
        index < currentNote.imagePaths.length) {
      final removedPath = currentNote.imagePaths[index];
      final newPaths = List<String>.from(currentNote.imagePaths);
      newPaths.removeAt(index);
      final newAnchors = List<int>.from(currentNote.imageAnchors);
      if (index < newAnchors.length) newAnchors.removeAt(index);
      final updatedNote = currentNote.copyWith(
        imagePaths: newPaths,
        imageAnchors: newAnchors,
        updatedAt: DateTime.now(),
      );
      try {
        await _updateNoteUseCase(updatedNote);
        note.value = updatedNote;
        await _deleteFile(removedPath);
      } catch (error) {
        _showError('Failed to remove the attachment. ${_readableError(error)}');
      }
    }
  }

  Future<void> _deleteFile(String path) async {
    try {
      await _attachmentRepository.delete(path);
    } catch (_) {
      // Database state is authoritative; stale files are safe to ignore.
    }
  }

  AttachmentFileRepository get _attachmentRepository =>
      _attachmentFiles ?? Get.find<AttachmentFileRepository>();

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      margin: const EdgeInsets.all(16),
      borderRadius: 15,
    );
  }

  void moveNote() {
    final currentNote = note.value;
    if (currentNote == null) return;

    HapticFeedback.selectionClick();
    Get.bottomSheet(
      MoveNoteSheet(
        note: currentNote,
        onMove: (folderId) async {
          try {
            final updatedNote = currentNote.copyWith(
              folderId: folderId,
              updatedAt: DateTime.now(),
            );
            await _updateNoteUseCase(updatedNote);
            note.value = updatedNote;
            Get.snackbar(
              'Moved',
              'Note moved successfully.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Get.theme.colorScheme.primary,
              colorText: Get.theme.colorScheme.onPrimary,
              borderRadius: 15,
              margin: const EdgeInsets.all(15),
              duration: const Duration(seconds: 2),
            );
          } catch (error) {
            _showError('Failed to move note. ${_readableError(error)}');
          }
        },
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  Future<void> togglePin() async {
    final currentNote = note.value;
    if (currentNote == null) return;

    final updatedNote = currentNote.copyWith(isPinned: !currentNote.isPinned);
    try {
      await _updateNoteUseCase(updatedNote);
      note.value = updatedNote;
      HapticFeedback.mediumImpact();
    } catch (error) {
      _showError('Failed to update pin. ${_readableError(error)}');
    }
  }

  String _readableError(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) return 'Please try again.';
    return message
        .replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '')
        .trim();
  }
}
