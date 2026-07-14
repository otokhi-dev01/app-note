import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/app/routes/app_routes.dart';
import 'package:notes/data/models/note_model.dart';
import 'package:notes/domain/usecases/get_note_usecase.dart';
import 'package:notes/domain/usecases/update_note_usecase.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../home/widgets/home_sheets.dart';
import 'package:notes/app/theme/colors.dart';
import 'image_editor_view.dart';

class DetailController extends GetxController {
  DetailController(this._getNoteUseCase, this._updateNoteUseCase);

  final GetNoteUseCase _getNoteUseCase;
  final UpdateNoteUseCase _updateNoteUseCase;
  
  final note = Rxn<NoteModel>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  int? get noteId {
    final argument = Get.arguments;
    return argument is int ? argument : null;
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
      final result = await _getNoteUseCase(id);

      if (result != null) {
        note.value = NoteModel.fromEntity(result);
      } else {
        errorMessage.value = 'Note not found.';
      }
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> edit() async {
    final currentNote = note.value;
    if (currentNote == null) return;

    final changed = await Get.toNamed(AppRoutes.editor, arguments: currentNote);

    if (changed == true) {
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
                  backgroundColor: AppColors.primary,
                  colorText: Colors.white,
                  icon: const Icon(CupertinoIcons.trash, color: Colors.white),
                  borderRadius: 15,
                  margin: const EdgeInsets.all(15),
                  duration: const Duration(seconds: 2),
                );
              } catch (e) {
                Get.snackbar('Error', 'Failed to delete note: $e');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> addImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (image != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'note_image_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
        final String filePath = p.join(directory.path, fileName);
        await File(image.path).copy(filePath);

        final currentNote = note.value;
        if (currentNote != null) {
          final updatedNote = currentNote.copyWith(
            imagePaths: [...currentNote.imagePaths, filePath],
            updatedAt: DateTime.now(),
          );
          await _updateNoteUseCase(updatedNote);
          note.value = updatedNote;
        }
      } catch (e) {
        errorMessage.value = 'Failed to add image: $e';
      }
    }
  }

  Future<void> editImage(String imagePath, int index) async {
    final editedPath = await Get.to<String>(() => ImageEditorView(imagePath: imagePath));

    if (editedPath != null) {
      final currentNote = note.value;
      if (currentNote != null) {
        final newPaths = List<String>.from(currentNote.imagePaths);
        newPaths[index] = editedPath;
        final updatedNote = currentNote.copyWith(
          imagePaths: newPaths,
          updatedAt: DateTime.now(),
        );
        await _updateNoteUseCase(updatedNote);
        note.value = updatedNote;
      }
    }
  }

  Future<void> removeImage(int index) async {
    final currentNote = note.value;
    if (currentNote != null) {
      final newPaths = List<String>.from(currentNote.imagePaths);
      newPaths.removeAt(index);
      final updatedNote = currentNote.copyWith(
        imagePaths: newPaths,
        updatedAt: DateTime.now(),
      );
      await _updateNoteUseCase(updatedNote);
      note.value = updatedNote;
    }
  }

  void moveNote() {
    final currentNote = note.value;
    if (currentNote == null) return;

    HapticFeedback.selectionClick();
    Get.bottomSheet(
      MoveNoteSheet(
        note: currentNote,
        onMove: (folderId) async {
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
            backgroundColor: AppColors.primary,
            colorText: Colors.white,
            borderRadius: 15,
            margin: const EdgeInsets.all(15),
            duration: const Duration(seconds: 2),
          );
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
    await _updateNoteUseCase(updatedNote);
    note.value = updatedNote;
    HapticFeedback.mediumImpact();
  }
}
