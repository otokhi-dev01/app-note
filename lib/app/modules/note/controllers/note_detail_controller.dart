import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../data/models/note_model.dart';
import '../../../data/providers/folder_service.dart';
import '../../../data/providers/note_service.dart';
import '../widgets/note_move_folder_modal.dart';
import 'note_controller.dart';

class NoteDetailController extends GetxController {
  final NoteService _noteService;
  final FolderService _folderService;
  final ImagePicker _picker = ImagePicker();

  NoteDetailController({
    required NoteService noteService,
    required FolderService folderService,
  }) : _noteService = noteService,
       _folderService = folderService;

  // --- Observables ---
  final currentNote = Rxn<NoteModel>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isReadOnly = false.obs;
  final isPinned = false.obs;
  final isArchived = false.obs;
  final isLocked = false.obs;

  // --- UI Controllers & Cache ---
  final titleController = TextEditingController();
  final blocks = <NoteBlock>[].obs;
  final Map<String, quill.QuillController> quillControllers = {};
  final Map<String, TextEditingController> textControllers = {};

  // --- State ---
  final activeBlockIndex = (-1).obs;
  final currentBlockStyle = "body".obs;
  final isSearchVisible = false.obs;
  final searchQuery = "".obs;
  final searchFocusNode = FocusNode();
  final isFormatPanelVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    _handleArguments(Get.arguments);
  }

  void _handleArguments(dynamic args) {
    if (args is Map) {
      final noteId = args['noteId'];
      final folderId = args['folderId'];
      isReadOnly.value = args['isDeleted'] == true;

      if (noteId != null && noteId != 0) {
        fetchNoteDetail(noteId);
      } else if (folderId != null) {
        _initNewNote(folderId);
      }
    }
  }

  Future<void> fetchNoteDetail(int id) async {
    isLoading.value = true;
    try {
      final note = await _noteService.getNoteDetail(id);
      _setupNoteState(note);
    } catch (e) {
      Get.snackbar("Error", "Could not load note detail");
    } finally {
      isLoading.value = false;
    }
  }

  void _setupNoteState(NoteModel note) {
    currentNote.value = note;
    titleController.text = note.title;
    isPinned.value = note.isPinned;
    isArchived.value = note.isArchived;
    isLocked.value = note.isLocked;

    _clearControllers();
    blocks.assignAll(note.content);

    if (blocks.isEmpty && !isReadOnly.value) {
      addTextBlock();
    }
  }

  void _initNewNote(int folderId) {
    currentNote.value = NoteModel(
      id: 0,
      folderId: folderId,
      title: '',
      folderName: '',
      content: [],
    );
    blocks.clear();
    addTextBlock();
    isLoading.value = false;
  }

  // --- Controller Management ---

  quill.QuillController getQuillController(String blockId, String content) {
    return quillControllers.putIfAbsent(blockId, () {
      quill.Document doc;
      try {
        final trimmed = content.trim();
        if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
          doc = quill.Document.fromJson(jsonDecode(content));
        } else {
          doc = quill.Document()..insert(0, content);
        }
      } catch (_) {
        doc = quill.Document()..insert(0, content);
      }
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    });
  }

  TextEditingController getTextController(String key, String initialValue) {
    return textControllers.putIfAbsent(
      key,
      () => TextEditingController(text: initialValue),
    );
  }

  // --- Block Actions ---

  void addTextBlock({String style = 'body'}) {
    _insertBlock(TextBlock(id: _generateId(), text: '', style: style));
  }

  void addChecklistBlock() {
    _insertBlock(
      ChecklistBlock(
        id: _generateId(),
        items: [ChecklistItem(id: _generateId(), text: '')],
      ),
    );
  }

  void addTableBlock() {
    _insertBlock(
      TableBlock(
        id: _generateId(),
        rows: [
          ['', ''],
          ['', ''],
        ],
      ),
    );
  }

  Future<void> addAttachment(ImageSource source, {bool isVideo = false}) async {
    if (isReadOnly.value) return;

    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source, imageQuality: 80);

      if (file == null) return;

      _insertBlock(
        AttachmentBlock(
          id: _generateId(),
          displayName: file.name,
          localPath: file.path,
          attachmentId: 0,
        ),
      );
      blocks.refresh();
      addTextBlock();
    } catch (e) {
      debugPrint('[CAMERA ERROR] $e');
      Get.snackbar(
        "Error",
        "Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}",
      );
    }
  }

  void updateAttachmentImage(int blockIndex, String editedPath) {
    if (isReadOnly.value || blockIndex < 0 || blockIndex >= blocks.length)
      return;
    final block = blocks[blockIndex];
    if (block is! AttachmentBlock) return;

    blocks[blockIndex] = AttachmentBlock(
      id: block.id,
      attachmentId: 0,
      displayName: 'Edited Image',
      localPath: editedPath,
      url: block.url,
    );
    blocks.refresh();
    saveNote();
  }

  void updateDrawing(int blockIndex, String path) {
    if (isReadOnly.value || blockIndex < 0 || blockIndex >= blocks.length)
      return;
    blocks[blockIndex] = DrawingBlock(
      id: blocks[blockIndex].id,
      localPath: path,
    );
    blocks.refresh();
  }

  // --- Checklist Actions ---

  void addChecklistItem(int blockIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is ChecklistBlock) {
      final newItems = List<ChecklistItem>.from(block.items)
        ..add(ChecklistItem(id: _generateId(), text: ''));
      blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
      blocks.refresh();
    }
  }

  void toggleChecklistItem(int blockIndex, int itemIndex) {
    final block = blocks[blockIndex];
    if (block is ChecklistBlock) {
      final item = block.items[itemIndex];
      final newItems = List<ChecklistItem>.from(block.items);
      newItems[itemIndex] = ChecklistItem(
        id: item.id,
        text: item.text,
        checked: !item.checked,
      );
      blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
      blocks.refresh();
    }
  }

  void onUpdateChecklistItem(int blockIndex, int itemIndex, String text) {
    final block = blocks[blockIndex];
    if (block is ChecklistBlock) {
      final item = block.items[itemIndex];
      final newItems = List<ChecklistItem>.from(block.items);
      newItems[itemIndex] = ChecklistItem(
        id: item.id,
        text: text,
        checked: item.checked,
      );
      blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
    }
  }

  void deleteChecklistItem(int blockIndex, int itemIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is ChecklistBlock && block.items.length > 1) {
      final newItems = List<ChecklistItem>.from(block.items)
        ..removeAt(itemIndex);
      blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
      blocks.refresh();
    }
  }

  // --- Table Actions ---

  void updateTableCell(
    int blockIndex,
    int rowIndex,
    int colIndex,
    String value,
  ) {
    final block = blocks[blockIndex];
    if (block is TableBlock) {
      final newRows = List<List<String>>.from(
        block.rows.map((r) => List<String>.from(r)),
      );
      newRows[rowIndex][colIndex] = value;
      blocks[blockIndex] = TableBlock(id: block.id, rows: newRows);
    }
  }

  void addTableRow(int blockIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is TableBlock) {
      final colCount = block.rows.isNotEmpty ? block.rows.first.length : 2;
      final newRows = List<List<String>>.from(block.rows)
        ..add(List.filled(colCount, ''));
      blocks[blockIndex] = TableBlock(id: block.id, rows: newRows);
      blocks.refresh();
    }
  }

  void addTableColumn(int blockIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is TableBlock) {
      final newRows = block.rows
          .map((r) => List<String>.from(r)..add(''))
          .toList();
      blocks[blockIndex] = TableBlock(id: block.id, rows: newRows);
      blocks.refresh();
    }
  }

  // --- Formatting ---

  void toggleFormatPanel() {
    if (isReadOnly.value) return;
    isFormatPanelVisible.toggle();
  }

  void applyInlineFormat(quill.Attribute attribute) {
    if (isReadOnly.value || activeBlockIndex.value < 0) return;
    final block = blocks[activeBlockIndex.value];
    if (block is TextBlock) {
      final qc = quillControllers[block.id];
      qc?.formatSelection(attribute);
    }
  }

  void updateActiveBlockStyle(String style) {
    if (isReadOnly.value || activeBlockIndex.value < 0) return;
    final block = blocks[activeBlockIndex.value];
    if (block is TextBlock) {
      blocks[activeBlockIndex.value] = TextBlock(
        id: block.id,
        text: block.text,
        style: style,
      );
      currentBlockStyle.value = style;
      blocks.refresh();
    }
  }

  // --- General Actions ---

  void deleteBlock(int index) {
    if (isReadOnly.value) return;
    blocks.removeAt(index);
    blocks.refresh();
  }

  void _insertBlock(NoteBlock block) {
    if (activeBlockIndex.value >= 0 && activeBlockIndex.value < blocks.length) {
      blocks.insert(activeBlockIndex.value + 1, block);
      activeBlockIndex.value++;
    } else {
      blocks.add(block);
      activeBlockIndex.value = blocks.length - 1;
    }
  }

  void _syncBlocks() {
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block is TextBlock) {
        final qc = quillControllers[block.id];
        if (qc != null) {
          final deltaJson = qc.document.toDelta().toJson();
          blocks[i] = TextBlock(
            id: block.id,
            text: jsonEncode(deltaJson),
            style: block.style,
          );
        }
      }
    }
  }

  // --- SAVE FLOW ---

  Future<void> saveNote() async {
    if (isSaving.value || isReadOnly.value) return;

    Get.focusScope?.unfocus();
    isSaving.value = true;

    try {
      _syncBlocks();

      final int folderId = currentNote.value?.folderId ?? 0;
      final String title = titleController.text.trim();
      int noteId = currentNote.value?.id ?? 0;

      noteId = await _noteService.saveNoteMetadata(
        folderId: folderId,
        title: title.isEmpty ? "Untitled Note" : title,
        noteId: noteId,
      );

      await _handleAttachmentUploads(noteId);

      await _noteService.saveNoteContent(
        noteId: noteId,
        title: title,
        content: blocks.toList(),
      );

      if (currentNote.value != null && currentNote.value!.id == 0) {
        fetchNoteDetail(noteId);
      }

      Get.snackbar(
        "Success",
        "Note saved",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } catch (e, s) {
      debugPrint('[SAVE ERROR] $e');
      debugPrintStack(stackTrace: s);
      Get.snackbar("Error", "Failed to save note");
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _handleAttachmentUploads(int noteId) async {
    bool stateChanged = false;
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block is AttachmentBlock &&
          block.attachmentId == 0 &&
          block.localPath != null) {
        try {
          final result = await _noteService.uploadAttachment(
            noteId,
            block.localPath!,
            block.id,
            i,
          );

          blocks[i] = AttachmentBlock(
            id: block.id,
            attachmentId: result['AttachmentId'] ?? 0,
            displayName: block.displayName,
            url: result['FilePath'],
            localPath: null,
          );
          stateChanged = true;
        } catch (e) {
          debugPrint('[UPLOAD ERROR] BlockId=${block.id}: $e');
        }
      }
    }
    if (stateChanged) blocks.refresh();
  }

  // --- MENU LOGIC ---

  void toggleSearch() {
    Get.back(); // Close More menu
    isSearchVisible.toggle();
    if (isSearchVisible.value) {
      Future.delayed(const Duration(milliseconds: 300), () {
        searchFocusNode.requestFocus();
      });
    } else {
      searchQuery.value = "";
    }
  }

  void shareNote() {
    _syncBlocks();
    String content = titleController.text + "\n\n";
    for (var b in blocks) {
      if (b is TextBlock) content += NoteModel.extractPlainText(b.text) + "\n";
    }
    Get.dialog(
      AlertDialog(
        title: const Text("Share Note"),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Close")),
        ],
      ),
    );
  }

  void undo() => Get.snackbar("Info", "Undo feature is coming soon");

  Future<void> togglePin() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;
    
    Get.back(); // Close menu
    final newState = !isPinned.value;
    try {
      await _noteService.updateNoteState(id, isPinned: newState);
      isPinned.value = newState;
      Get.find<NoteController>().fetchNotes(refresh: true);
    } catch (e) {
      Get.snackbar("Error", "Could not update pin state");
    }
  }

  Future<void> toggleArchive() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;
    
    Get.back(); // Close menu
    final newState = !isArchived.value;
    try {
      await _noteService.updateNoteState(id, isArchived: newState);
      isArchived.value = newState;
      Get.find<NoteController>().fetchNotes(refresh: true);
      if (newState) Get.back(result: true); // Go back if archived
    } catch (e) {
      Get.snackbar("Error", "Could not update archive state");
    }
  }

  Future<void> toggleLock() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;
    
    Get.back(); // Close menu
    final newState = !isLocked.value;
    try {
      await _noteService.updateNoteState(id, isLocked: newState);
      isLocked.value = newState;
    } catch (e) {
      Get.snackbar("Error", "Could not update lock state");
    }
  }

  Future<void> deleteNote() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;
    
    Get.back(); // Close menu
    try {
      await _noteService.updateNoteState(id, isDelete: true);
      Get.find<NoteController>().fetchNotes(refresh: true);
      Get.back(result: true); // Back to list
      Get.snackbar("Success", "Moved to Recently Deleted");
    } catch (e) {
      Get.snackbar("Error", "Could not delete note");
    }
  }

  Future<void> moveNote() async {
    Get.back(); // Close menu
    if (isLoading.value || currentNote.value == null) return;
    
    try {
      final response = await _folderService.getFolders();
      if (response.folders.isEmpty) {
        Get.snackbar("Info", "Create another folder first");
        return;
      }

      Get.to(
        () => NoteMoveFolderModal(
          folders: response.folders,
          currentFolderId: currentNote.value!.folderId,
          onFolderSelected: (targetFolder) async {
            Get.back(); // Pop modal
            isLoading.value = true;
            try {
              await _noteService.saveNoteMetadata(
                folderId: targetFolder.id,
                title: titleController.text,
                noteId: currentNote.value!.id,
              );
              await fetchNoteDetail(currentNote.value!.id);
              Get.find<NoteController>().fetchNotes(refresh: true);
              Get.snackbar("Success", "Moved to ${targetFolder.name}");
            } finally {
              isLoading.value = false;
            }
          },
        ),
        fullscreenDialog: true,
        transition: Transition.cupertino,
      );
    } catch (e) {
      Get.snackbar("Error", "Could not load folders");
    }
  }

  void _clearControllers() {
    for (var c in quillControllers.values) c.dispose();
    quillControllers.clear();
    for (var c in textControllers.values) c.dispose();
    textControllers.clear();
  }

  @override
  void onClose() {
    titleController.dispose();
    _clearControllers();
    searchFocusNode.dispose();
    super.onClose();
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
