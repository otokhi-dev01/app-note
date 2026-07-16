import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/app/navigation/route_contracts.dart';
import 'package:notes/features/notes/application/editor/note_formatting_service.dart';
import 'package:notes/features/notes/domain/entities/note.dart';
import 'package:notes/features/notes/domain/repositories/attachment_file_repository.dart';
import 'package:notes/features/notes/domain/usecases/create_note_usecase.dart';
import 'package:notes/features/notes/domain/usecases/update_note_usecase.dart';

import '../detail/image_editor_view.dart';
import 'sketch_view.dart';

export 'package:notes/app/navigation/route_contracts.dart' show EditorResult;

class EditorController extends GetxController {
  EditorController(
    this._createNoteUseCase,
    this._updateNoteUseCase, {
    AttachmentFileRepository? attachmentFiles,
  }) : _attachmentFiles = attachmentFiles;

  final CreateNoteUseCase _createNoteUseCase;
  final UpdateNoteUseCase _updateNoteUseCase;
  final AttachmentFileRepository? _attachmentFiles;
  final NoteFormattingService _formattingService =
      const NoteFormattingService();

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final contentFocusNode = FocusNode();

  final isSaving = false.obs;
  final canPop = true.obs;
  final imagePaths = <String>[].obs;
  Note? existingNote;
  int? initialFolderId;

  late final String _initialTitle;
  late final String _initialContent;
  late final List<String> _initialImagePaths;
  late final Worker _imagePathsWorker;
  final _createdImagePaths = <String>{};
  bool _isCloseDialogOpen = false;

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

    final arguments = NoteEditorArguments.from(Get.arguments);
    final note = arguments.note;
    if (note != null) {
      existingNote = note;
      titleController.text = note.title;
      contentController.text = note.content;
      imagePaths.assignAll(note.imagePaths);
    } else {
      initialFolderId = arguments.folderId;
    }

    _initialTitle = titleController.text;
    _initialContent = contentController.text;
    _initialImagePaths = imagePaths.toList(growable: false);
    _lastText = contentController.text;
    titleController.addListener(_updateDirtyState);
    contentController.addListener(_onContentChanged);
    _imagePathsWorker = ever<List<String>>(
      imagePaths,
      (_) => _updateDirtyState(),
    );
  }

  bool get hasUnsavedChanges {
    if (titleController.text != _initialTitle ||
        contentController.text != _initialContent ||
        imagePaths.length != _initialImagePaths.length) {
      return true;
    }

    for (var index = 0; index < imagePaths.length; index++) {
      if (imagePaths[index] != _initialImagePaths[index]) return true;
    }
    return false;
  }

  void _updateDirtyState() {
    canPop.value = !hasUnsavedChanges;
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
    _updateDirtyState();
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
    _updateDirtyState();
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
    _updateDirtyState();
    update(['undo_redo']);
  }

  Future<void> requestClose() async {
    if (isSaving.value || _isCloseDialogOpen) return;

    if (!hasUnsavedChanges) {
      Get.back();
      return;
    }

    _isCloseDialogOpen = true;
    final shouldDiscard = await Get.dialog<bool>(
      CupertinoAlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep Editing'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Get.back(result: true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _isCloseDialogOpen = false;

    if (shouldDiscard == true) {
      await _deleteFiles(_createdImagePaths);
      await _closeEditor();
    }
  }

  Future<void> _closeEditor({EditorResult? result}) async {
    canPop.value = true;
    await WidgetsBinding.instance.endOfFrame;
    Get.back(result: result);
  }

  void toggleChecklist() {
    _applyFormattingValue(
      _formattingService.toggleChecklist(_currentFormattingValue),
    );
    HapticFeedback.mediumImpact();
  }

  void addTag(String tag) {
    _applyFormattingValue(
      _formattingService.addTag(_currentFormattingValue, tag),
    );
    HapticFeedback.lightImpact();
  }

  void applyInlineFormat(String prefix, String suffix) {
    _applyFormattingValue(
      _formattingService.applyInlineFormat(
        _currentFormattingValue,
        prefix: prefix,
        suffix: suffix,
      ),
    );
    HapticFeedback.selectionClick();
  }

  void applyLineFormat(String prefix) {
    _applyFormattingValue(
      _formattingService.applyLineFormat(_currentFormattingValue, prefix),
    );
    HapticFeedback.selectionClick();
  }

  void insertTable() {
    _applyFormattingValue(
      _formattingService.insertTable(_currentFormattingValue),
    );
    HapticFeedback.mediumImpact();
  }

  NoteFormattingValue get _currentFormattingValue {
    final selection = contentController.selection;
    return NoteFormattingValue(
      text: contentController.text,
      selectionStart: selection.start,
      selectionEnd: selection.end,
    );
  }

  void _applyFormattingValue(NoteFormattingValue value) {
    contentController.text = value.text;
    contentController.selection = TextSelection(
      baseOffset: value.selectionStart,
      extentOffset: value.selectionEnd,
    );
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a note title.';
    }
    return null;
  }

  Future<void> copyToClipboard() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    final text = title.isEmpty ? content : '$title\n\n$content';
    if (text.trim().isEmpty) {
      Get.snackbar('Nothing to copy', 'Add a title or note text first.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    Get.snackbar('Copied', 'Note content copied to clipboard.');
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    try {
      isSaving.value = true;
      final now = DateTime.now();

      if (existingNote == null) {
        await _createNoteUseCase(
          Note(
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            createdAt: now,
            updatedAt: now,
            imagePaths: imagePaths.toList(),
            folderId: initialFolderId,
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

      final currentPaths = imagePaths.toSet();
      await _deleteFiles(<String>{
        ..._initialImagePaths.where((path) => !currentPaths.contains(path)),
        ..._createdImagePaths.where((path) => !currentPaths.contains(path)),
      });
      await _closeEditor(result: EditorResult.saved);
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
        final filePath = await _attachmentRepository.importImage(image.path);
        _createdImagePaths.add(filePath);
        imagePaths.add(filePath);
      } catch (e) {
        Get.snackbar('Error', 'Failed to add image: $e');
      }
    }
  }

  Future<void> editImage(int index) async {
    final imagePath = imagePaths[index];
    final editedPath = await Get.to<String>(
      () => ImageEditorView(imagePath: imagePath),
    );

    if (editedPath != null) {
      if (editedPath != imagePath) _createdImagePaths.add(editedPath);
      imagePaths[index] = editedPath;
    }
  }

  Future<void> openSketch() async {
    final sketchPath = await Get.to<String>(() => const SketchView());
    if (sketchPath != null) {
      _createdImagePaths.add(sketchPath);
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
        final filePath = await _attachmentRepository.importImage(image.path);
        _createdImagePaths.add(filePath);
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
      await _deleteFiles(_createdImagePaths);
      await _closeEditor();
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
                await _deleteFiles(_createdImagePaths);

                // Go back to previous screen (Home)
                await _closeEditor(result: EditorResult.deleted);
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

  Future<void> _deleteFiles(Iterable<String> paths) async {
    await _attachmentRepository.deleteAll(paths.toSet());
  }

  AttachmentFileRepository get _attachmentRepository =>
      _attachmentFiles ?? Get.find<AttachmentFileRepository>();

  @override
  void onClose() {
    _imagePathsWorker.dispose();
    titleController.removeListener(_updateDirtyState);
    contentController.removeListener(_onContentChanged);
    titleController.dispose();
    contentController.dispose();
    contentFocusNode.dispose();
    super.onClose();
  }
}
