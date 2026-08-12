import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../data/models/note_model.dart';
import '../../../data/providers/folder_service.dart';
import '../../../data/providers/note_service.dart';
import 'note_controller.dart';

class NoteDetailController extends GetxController {
  final NoteService _noteService;
  final ImagePicker _picker = ImagePicker();

  NoteDetailController({
    required NoteService noteService,
    required FolderService folderService,
  }) : _noteService = noteService;

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

    // We reset attachmentId to 0 so it gets re-uploaded on next save
    blocks[blockIndex] = AttachmentBlock(
      id: block.id,
      attachmentId: 0,
      displayName: 'Edited Image',
      localPath: editedPath,
      url: block.url, // Keep old URL as reference until sync
    );
    blocks.refresh();

    // Automatically trigger a save if the user just edited an image
    // This satisfies "user can save when user edit image"
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

      // 1. Metadata Save (Get NoteId)
      noteId = await _noteService.saveNoteMetadata(
        folderId: folderId,
        title: title.isEmpty ? "Untitled Note" : title,
        noteId: noteId,
      );

      // 2. Upload Attachments & Update blocks with real AttachmentId
      await _handleAttachmentUploads(noteId);

      // 3. Final Content Sync
      await _noteService.saveNoteContent(
        noteId: noteId,
        title: title,
        content: blocks.toList(),
      );

      // Update current note state so we don't think it's unsaved
      if (currentNote.value != null && currentNote.value!.id == 0) {
        // If it was a new note, we might want to refresh to get full server object
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

  void toggleSearch() {
    isSearchVisible.toggle();
    if (isSearchVisible.value)
      searchFocusNode.requestFocus();
    else
      searchQuery.value = "";
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
    
    final newState = !isPinned.value;
    await _noteService.updateNoteState(id, isPinned: newState);
    isPinned.value = newState;
    
    // Refresh to sync list view
    Get.find<NoteController>().fetchNotes(refresh: true);
  }

  Future<void> toggleArchive() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;
    
    final newState = !isArchived.value;
    await _noteService.updateNoteState(id, isArchived: newState);
    isArchived.value = newState;
    
    // Refresh list and go back as archived notes usually disappear from the main list
    Get.find<NoteController>().fetchNotes(refresh: true);
    Get.back(result: true);
  }

  Future<void> toggleLock() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;
    
    final newState = !isLocked.value;
    await _noteService.updateNoteState(id, isLocked: newState);
    isLocked.value = newState;
  }

  Future<void> deleteNote() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;
    
    // Task: Integrated with /api/note/update-state via updateNoteState(isDelete: true)
    await _noteService.updateNoteState(id, isDelete: true);
    
    Get.find<NoteController>().fetchNotes(refresh: true);
    Get.back(); // Close popup
    Get.back(result: true); // Close detail view
  }

  Future<void> moveNote() async {
    Get.snackbar("Info", "Move functionality is coming soon");
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
