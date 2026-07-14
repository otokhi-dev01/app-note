import 'dart:io';
import 'package:flutter/services.dart';
import 'package:notes/domain/entities/note.dart';
import 'package:notes/domain/usecases/create_note_usecase.dart';
import 'package:notes/domain/usecases/update_note_usecase.dart';
import 'package:notes/domain/usecases/delete_note_usecase.dart';
import 'package:notes/data/models/note_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../detail/image_editor_view.dart';
import 'sketch_view.dart';

class EditorController extends GetxController {
  EditorController(
    this._createNoteUseCase, 
    this._updateNoteUseCase,
    this._deleteNoteUseCase,
  );

  final CreateNoteUseCase _createNoteUseCase;
  final UpdateNoteUseCase _updateNoteUseCase;
  final DeleteNoteUseCase _deleteNoteUseCase;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final contentFocusNode = FocusNode();

  final isSaving = false.obs;
  final imagePaths = <String>[].obs;
  NoteModel? existingNote;

  // Undo/Redo Stacks
  final _undoStack = <String>[];
  final _redoStack = <String>[];
  String? _lastText;

  bool get isEditing => existingNote != null;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  void onInit() {
    super.onInit();

    final argument = Get.arguments;
    if (argument is Note) {
      existingNote = NoteModel.fromEntity(argument);
      titleController.text = argument.title;
      contentController.text = argument.content;
      imagePaths.assignAll(argument.imagePaths);
    }

    _lastText = contentController.text;
    contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    final newText = contentController.text;
    if (newText != _lastText) {
      if (_undoStack.length > 50) _undoStack.removeAt(0);
      _undoStack.add(_lastText!);
      _redoStack.clear();
      _lastText = newText;
      update(['undo_redo']);
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final text = _undoStack.removeLast();
    _redoStack.add(contentController.text);
    _lastText = text;
    
    contentController.removeListener(_onContentChanged);
    contentController.text = text;
    contentController.selection = TextSelection.collapsed(offset: text.length);
    contentController.addListener(_onContentChanged);
    
    HapticFeedback.lightImpact();
    update(['undo_redo']);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final text = _redoStack.removeLast();
    _undoStack.add(contentController.text);
    _lastText = text;

    contentController.removeListener(_onContentChanged);
    contentController.text = text;
    contentController.selection = TextSelection.collapsed(offset: text.length);
    contentController.addListener(_onContentChanged);

    HapticFeedback.lightImpact();
    update(['undo_redo']);
  }

  void toggleChecklist() {
    final text = contentController.text;
    final selection = contentController.selection;
    
    // Simple logic: insert checkbox at start of line or cursor
    const checkbox = '☐ ';
    final newText = text.replaceRange(selection.start, selection.end, checkbox);
    
    contentController.text = newText;
    contentController.selection = TextSelection.collapsed(offset: selection.start + checkbox.length);
    HapticFeedback.mediumImpact();
  }

  void addTag(String tag) {
    final text = contentController.text;
    final selection = contentController.selection;
    final tagWithSpace = '$tag ';
    
    final newText = text.replaceRange(selection.start, selection.end, tagWithSpace);
    contentController.text = newText;
    contentController.selection = TextSelection.collapsed(offset: selection.start + tagWithSpace.length);
    HapticFeedback.lightImpact();
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a note title.';
    }
    return null;
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    try {
      isSaving.value = true;
      final now = DateTime.now();

      if (existingNote == null) {
        await _createNoteUseCase(
          NoteModel(
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            createdAt: now,
            updatedAt: now,
            imagePaths: imagePaths.toList(),
          ),
        );
      } else {
        await _updateNoteUseCase(
          existingNote!.copyWith(
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            updatedAt: now,
            imagePaths: imagePaths.toList(),
          ),
        );
      }

      Get.back(result: true);
    } catch (error) {
      Get.snackbar('Save failed', error.toString());
    } finally {
      isSaving.value = false;
    }
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
        imagePaths.add(filePath);
      } catch (e) {
        Get.snackbar('Error', 'Failed to add image: $e');
      }
    }
  }

  Future<void> editImage(int index) async {
    final imagePath = imagePaths[index];
    final editedPath = await Get.to<String>(() => ImageEditorView(imagePath: imagePath));

    if (editedPath != null) {
      imagePaths[index] = editedPath;
    }
  }

  Future<void> openSketch() async {
    final sketchPath = await Get.to<String>(() => const SketchView());
    if (sketchPath != null) {
      imagePaths.add(sketchPath);
    }
  }

  Future<void> replaceImage(int index, ImageSource source) async {
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
        imagePaths[index] = filePath;
      } catch (e) {
        Get.snackbar('Error', 'Failed to update image: $e');
      }
    }
  }

  void removeImage(int index) {
    imagePaths.removeAt(index);
  }

  Future<void> delete() async {
    final note = existingNote;
    if (note == null) {
      Get.back();
      return;
    }

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
                final updatedNote = note.copyWith(
                  isDeleted: true,
                  deletedAt: DateTime.now(),
                );

                await _updateNoteUseCase(updatedNote);
                
                // Go back to previous screen (Home)
                Get.back(result: true); 
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

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    contentFocusNode.dispose();
    super.onClose();
  }
}
