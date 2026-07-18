import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/app/navigation/route_contracts.dart';
import 'package:notes/core/presentation/images/image_picker_feedback.dart';
import 'package:notes/core/presentation/images/note_image_picker.dart';
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
    NoteImagePicker? imagePicker,
  }) : _attachmentFiles = attachmentFiles,
       _imagePicker = imagePicker ?? SystemNoteImagePicker();

  final CreateNoteUseCase _createNoteUseCase;
  final UpdateNoteUseCase _updateNoteUseCase;
  final AttachmentFileRepository? _attachmentFiles;
  final NoteImagePicker _imagePicker;
  final NoteFormattingService _formattingService =
      const NoteFormattingService();
  String Function()? _activeStatementText;
  TextSelection Function()? _activeStatementSelection;
  void Function(String text, TextSelection selection)? _applyToActiveStatement;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final titleFocusNode = FocusNode();
  final contentController = TextEditingController();
  final contentFocusNode = FocusNode();
  VoidCallback? focusStatementComposer;
  VoidCallback? focusFirstStatementComposer;

  final isSaving = false.obs;
  final canPop = true.obs;
  final activeStatementIndex = 0.obs;
  final imagePaths = <String>[].obs;
  final imageAnchors = <int>[].obs;
  Note? existingNote;
  int? initialFolderId;

  late final String _initialTitle;
  late final String _initialContent;
  late final List<String> _initialImagePaths;
  late final List<int> _initialImageAnchors;
  late final Worker _imagePathsWorker;
  late final Worker _imageAnchorsWorker;
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
      imageAnchors.assignAll(_normalizedAnchors(note));
    } else {
      initialFolderId = arguments.folderId;
    }

    _initialTitle = titleController.text;
    _initialContent = contentController.text;
    _initialImagePaths = imagePaths.toList(growable: false);
    _initialImageAnchors = imageAnchors.toList(growable: false);
    activeStatementIndex.value = statementCount - 1;
    _lastText = contentController.text;
    titleController.addListener(_updateDirtyState);
    contentController.addListener(_onContentChanged);
    _imagePathsWorker = ever<List<String>>(
      imagePaths,
      (_) => _updateDirtyState(),
    );
    _imageAnchorsWorker = ever<List<int>>(
      imageAnchors,
      (_) => _updateDirtyState(),
    );
  }

  List<int> _normalizedAnchors(Note note) {
    final lastStatement = _statementCount(note.content) - 1;
    return List<int>.generate(note.imagePaths.length, (index) {
      if (index < note.imageAnchors.length) {
        return note.imageAnchors[index].clamp(0, lastStatement);
      }
      return lastStatement;
    });
  }

  int _statementCount(String value) => value.split('\n').length.clamp(1, 9999);

  int get statementCount => _statementCount(contentController.text);

  void focusContent() {
    (focusStatementComposer ?? contentFocusNode.requestFocus).call();
  }

  void focusFirstStatement() {
    (focusFirstStatementComposer ?? focusContent).call();
  }

  void setActiveStatement(int index) {
    activeStatementIndex.value = index.clamp(0, statementCount - 1);
  }

  void bindActiveStatementEditor({
    required String Function() text,
    required TextSelection Function() selection,
    required void Function(String text, TextSelection selection) apply,
  }) {
    _activeStatementText = text;
    _activeStatementSelection = selection;
    _applyToActiveStatement = apply;
  }

  void unbindActiveStatementEditor() {
    _activeStatementText = null;
    _activeStatementSelection = null;
    _applyToActiveStatement = null;
  }

  void setStatements(List<String> statements) {
    final value = statements.isEmpty ? '' : statements.join('\n');
    if (contentController.text == value) return;
    final oldLast = statementCount - 1;
    contentController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    final newLast = statementCount - 1;
    if (newLast < oldLast) {
      for (var index = 0; index < imageAnchors.length; index++) {
        imageAnchors[index] = imageAnchors[index].clamp(0, newLast);
      }
    }
  }

  List<int> imagesAfterStatement(int statementIndex) {
    return List<int>.generate(imagePaths.length, (index) => index)
        .where((index) => imageAnchors[index] == statementIndex)
        .toList(growable: false);
  }

  void statementInsertedAfter(int statementIndex) {
    for (var index = 0; index < imageAnchors.length; index++) {
      if (imageAnchors[index] > statementIndex) {
        imageAnchors[index]++;
      }
    }
  }

  void statementRemoved(int statementIndex) {
    for (var index = 0; index < imageAnchors.length; index++) {
      final anchor = imageAnchors[index];
      if (anchor == statementIndex) {
        imageAnchors[index] = (statementIndex - 1).clamp(0, 9999);
      } else if (anchor > statementIndex) {
        imageAnchors[index]--;
      }
    }
    final active = activeStatementIndex.value;
    if (active > statementIndex) {
      activeStatementIndex.value = active - 1;
    } else if (active == statementIndex) {
      activeStatementIndex.value = (statementIndex - 1).clamp(0, 9999);
    }
  }

  bool get hasUnsavedChanges {
    if (titleController.text != _initialTitle ||
        contentController.text != _initialContent ||
        imagePaths.length != _initialImagePaths.length) {
      return true;
    }

    for (var index = 0; index < imagePaths.length; index++) {
      if (imagePaths[index] != _initialImagePaths[index]) return true;
      if (index >= _initialImageAnchors.length ||
          imageAnchors[index] != _initialImageAnchors[index]) {
        return true;
      }
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
    final text = _activeStatementText?.call() ?? contentController.text;
    final rawSelection =
        _activeStatementSelection?.call() ?? contentController.selection;
    final selection = rawSelection.isValid
        ? rawSelection
        : TextSelection.collapsed(offset: text.length);
    return NoteFormattingValue(
      text: text,
      selectionStart: selection.start,
      selectionEnd: selection.end,
    );
  }

  void _applyFormattingValue(NoteFormattingValue value) {
    final selection = TextSelection(
      baseOffset: value.selectionStart,
      extentOffset: value.selectionEnd,
    );
    final applyToStatement = _applyToActiveStatement;
    if (applyToStatement != null) {
      applyToStatement(value.text, selection);
      return;
    }
    contentController.text = value.text;
    contentController.selection = selection;
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
    if (kDebugMode) {
      debugPrint('[EditorController.save] tapped. isSaving=${isSaving.value}');
    }
    if (isSaving.value) return;
    final form = formKey.currentState;
    if (form == null || !form.validate()) {
      if (kDebugMode) {
        debugPrint(
          '[EditorController.save] validation failed. form=${form == null ? 'null' : 'present'}',
        );
      }
      titleFocusNode.requestFocus();
      Get.snackbar('Title required', 'Enter a title before saving this note.');
      return;
    }

    try {
      isSaving.value = true;
      final now = DateTime.now();

      if (existingNote == null) {
        if (kDebugMode) {
          debugPrint(
            '[EditorController.save] creating note '
            'title="${titleController.text.trim()}" '
            'contentLength=${contentController.text.length} '
            'images=${imagePaths.length} folderId=$initialFolderId',
          );
        }
        final newId = await _createNoteUseCase(
          Note(
            title: titleController.text.trim(),
            content: contentController.text,
            createdAt: now,
            updatedAt: now,
            imagePaths: imagePaths.toList(),
            imageAnchors: imageAnchors.toList(),
            folderId: initialFolderId,
          ),
        );
        if (kDebugMode) {
          debugPrint('[EditorController.save] create succeeded id=$newId');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '[EditorController.save] updating note id=${existingNote!.id} '
            'title="${titleController.text.trim()}" '
            'contentLength=${contentController.text.length} '
            'images=${imagePaths.length}',
          );
        }
        final updated = await _updateNoteUseCase(
          existingNote!.copyWith(
            title: titleController.text.trim(),
            content: contentController.text,
            updatedAt: now,
            imagePaths: imagePaths.toList(),
            imageAnchors: imageAnchors.toList(),
          ),
        );
        if (kDebugMode) {
          debugPrint(
            '[EditorController.save] update succeeded result=$updated',
          );
        }
      }

      final currentPaths = imagePaths.toSet();
      await _deleteFiles(<String>{
        ..._initialImagePaths.where((path) => !currentPaths.contains(path)),
        ..._createdImagePaths.where((path) => !currentPaths.contains(path)),
      });
      if (kDebugMode) {
        debugPrint('[EditorController.save] closing editor with saved result');
      }
      await _closeEditor(result: EditorResult.saved);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[EditorController.save] FAILED: $error');
        debugPrint('[EditorController.save] stackTrace:\n$stackTrace');
      }
      Get.snackbar('Save failed', error.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> addImage(ImageSource source, {int? afterStatement}) async {
    final image = await _pickImage(
      source,
      onUsePhotoLibrary: source == ImageSource.camera
          ? () => addImage(ImageSource.gallery, afterStatement: afterStatement)
          : null,
    );
    if (image == null) return;

    try {
      final filePath = await _attachmentRepository.importImage(image.path);
      _createdImagePaths.add(filePath);
      imageAnchors.add(
        (afterStatement ?? activeStatementIndex.value).clamp(
          0,
          statementCount - 1,
        ),
      );
      imagePaths.add(filePath);
    } catch (error) {
      Get.snackbar('Image not added', 'The selected image could not be saved.');
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
      imageAnchors.add(activeStatementIndex.value.clamp(0, statementCount - 1));
      imagePaths.add(sketchPath);
    }
  }

  Future<void> replaceImage(int index, ImageSource source) async {
    final image = await _pickImage(
      source,
      onUsePhotoLibrary: source == ImageSource.camera
          ? () => replaceImage(index, ImageSource.gallery)
          : null,
    );
    if (image == null) return;

    try {
      final filePath = await _attachmentRepository.importImage(image.path);
      _createdImagePaths.add(filePath);
      imagePaths[index] = filePath;
    } catch (error) {
      Get.snackbar(
        'Image not replaced',
        'The selected image could not be saved.',
      );
    }
  }

  Future<XFile?> _pickImage(
    ImageSource source, {
    Future<void> Function()? onUsePhotoLibrary,
  }) async {
    try {
      return await _imagePicker.pickImage(source: source, imageQuality: 90);
    } on PlatformException catch (error) {
      final usePhotoLibrary = await ImagePickerFeedback.show(
        error,
        source: source,
      );
      if (usePhotoLibrary && onUsePhotoLibrary != null) {
        await onUsePhotoLibrary();
      }
      return null;
    } catch (_) {
      Get.snackbar(
        'Unable to open images',
        'The image picker could not be opened. Please try again.',
      );
      return null;
    }
  }

  void removeImage(int index) {
    imagePaths.removeAt(index);
    imageAnchors.removeAt(index);
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
    final uniquePaths = paths.toSet();
    if (uniquePaths.isEmpty) return;
    await _attachmentRepository.deleteAll(uniquePaths);
  }

  AttachmentFileRepository get _attachmentRepository =>
      _attachmentFiles ?? Get.find<AttachmentFileRepository>();

  @override
  void onClose() {
    _imagePathsWorker.dispose();
    _imageAnchorsWorker.dispose();
    titleController.removeListener(_updateDirtyState);
    contentController.removeListener(_onContentChanged);
    titleController.dispose();
    titleFocusNode.dispose();
    contentController.dispose();
    contentFocusNode.dispose();
    super.onClose();
  }
}
