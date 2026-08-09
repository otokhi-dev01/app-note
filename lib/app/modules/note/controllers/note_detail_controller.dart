import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../data/models/note_model.dart';
import '../../../data/providers/folder_service.dart';
import '../../../data/providers/note_service.dart';
import '../widgets/note_move_folder_modal.dart';

class NoteDetailController extends GetxController {
  final NoteService _noteService;
  final FolderService _folderService;
  final ImagePicker _picker = ImagePicker();

  NoteDetailController({
    required NoteService noteService,
    required FolderService folderService,
  })  : _noteService = noteService,
        _folderService = folderService;

  // --- Observables ---
  final currentNote = Rxn<NoteModel>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isReadOnly = false.obs;
  final isPinned = false.obs;
  final isArchived = false.obs;
  final isLocked = false.obs;

  // --- UI Controllers ---
  final titleController = TextEditingController();
  final blocks = <NoteBlock>[].obs;
  final Map<String, TextEditingController> blockControllers = {};
  final Map<String, quill.QuillController> quillControllers = {};

  // --- State ---
  final _history = <List<NoteBlock>>[];
  final _redoStack = <List<NoteBlock>>[];
  static const int _maxHistory = 30;
  final activeBlockIndex = (-1).obs;

  final isSearchVisible = false.obs;
  final searchQuery = "".obs;
  final searchFocusNode = FocusNode();

  final isFormatPanelVisible = false.obs;
  final currentBlockStyle = "body".obs;
  final activeAttributes = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _handleArguments(Get.arguments);
    
    // Sync currentBlockStyle when activeBlockIndex changes
    ever(activeBlockIndex, (index) {
      if (index >= 0 && index < blocks.length) {
        final block = blocks[index];
        if (block is TextBlock) {
          currentBlockStyle.value = block.style;
          
          // Also sync active attributes if Quill controller exists
          final qc = quillControllers[block.id];
          if (qc != null) {
            _updateActiveAttributes(qc);
          }
        }
      }
    });
  }

  @override
  void onClose() {
    titleController.dispose();
    for (final controller in blockControllers.values) {
      controller.dispose();
    }
    blockControllers.clear();
    for (final controller in quillControllers.values) {
      controller.dispose();
    }
    quillControllers.clear();
    super.onClose();
  }

  // --- Initialization ---

  void _handleArguments(dynamic args) {
    if (kDebugMode) debugPrint('NoteDetailController.onInit with args: $args');

    if (args is Map) {
      final noteId = _toInt(args['noteId']);
      final folderId = _toInt(args['folderId']);

      isReadOnly.value = args['isDeleted'] == true;

      if (noteId != null && noteId != 0) {
        final note = args['note'];
        if (isReadOnly.value && note is NoteModel) {
          _setupNoteState(note);
          isLoading.value = false;
        } else {
          fetchNoteDetail(noteId);
        }
      } else if (folderId != null) {
        _initNewNote(folderId);
      } else {
        Get.back();
      }
    } else {
      Get.back();
    }
  }

  Future<void> fetchNoteDetail(int id) async {
    isLoading.value = true;
    try {
      final note = await _noteService.getNoteDetail(id);
      _setupNoteState(note);
    } catch (error, stackTrace) {
      _handleError('Could not load note detail', error, stackTrace);
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
    _history.clear();

    if (kDebugMode) {
      debugPrint('[NOTE DETAIL] Blocks parsed: ${blocks.length}');
      for (var i = 0; i < blocks.length; i++) {
        debugPrint('  Block $i: ${blocks[i].type} (ID: ${blocks[i].id})');
      }
    }

    if (blocks.isEmpty && !isReadOnly.value) {
      addTextBlock();
    }
  }

  void _initNewNote(int folderId) {
    currentNote.value = NoteModel(id: 0, folderId: folderId, title: '', folderName: '');
    isPinned.value = false;
    isArchived.value = false;
    isLocked.value = false;
    titleController.clear();
    blocks.clear();
    _history.clear();
    addTextBlock();
    isLoading.value = false;
  }

  // --- Content Management ---
  TextEditingController getTextController(String blockId, String initialText) {
    return blockControllers.putIfAbsent(blockId, () => TextEditingController(text: initialText));
  }

  quill.QuillController getQuillController(String blockId, String content) {
    return quillControllers.putIfAbsent(blockId, () {
      quill.Document doc;
      try {
        if (content.startsWith('[') || content.startsWith('{')) {
          doc = quill.Document.fromJson(jsonDecode(content));
        } else {
          doc = quill.Document()..insert(0, content);
        }
      } catch (_) {
        doc = quill.Document()..insert(0, content);
      }
      final controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
      
      // Listen to selection changes to update formatting UI
      controller.addListener(() {
        if (activeBlockIndex.value != -1 && blocks[activeBlockIndex.value].id == blockId) {
          _updateActiveAttributes(controller);
        }
      });
      
      return controller;
    });
  }

  void _updateActiveAttributes(quill.QuillController controller) {
    final attrs = controller.getSelectionStyle().attributes;
    final Map<String, dynamic> newAttrs = {};
    attrs.forEach((key, value) {
      newAttrs[key] = value.value;
    });
    activeAttributes.assignAll(newAttrs);
  }

  void updateTextBlock(int index, String text) {
    if (index < 0 || index >= blocks.length) return;
    final block = blocks[index];
    if (block is TextBlock) {
      blocks[index] = TextBlock(id: block.id, text: text, style: block.style);
    }
  }

  void updateQuillBlock(int index, String jsonContent) {
    if (index < 0 || index >= blocks.length) return;
    final block = blocks[index];
    if (block is TextBlock) {
      blocks[index] = TextBlock(id: block.id, text: jsonContent, style: block.style);
    }
  }

  void updateTextBlockStyle(int index, String style) {
    if (isReadOnly.value || index < 0 || index >= blocks.length) return;
    _recordHistory();
    final block = blocks[index];
    if (block is TextBlock) {
      blocks[index] = TextBlock(id: block.id, text: block.text, style: style);
      
      // Update Quill controller if exists to match style (Header)
      final controller = quillControllers[block.id];
      if (controller != null) {
        quill.Attribute? headerAttr;
        switch (style) {
          case 'title': headerAttr = quill.Attribute.h1; break;
          case 'heading': headerAttr = quill.Attribute.h2; break;
          case 'subheading': headerAttr = quill.Attribute.h3; break;
          default: headerAttr = quill.Attribute.header; break; // Remove header
        }
        controller.formatSelection(headerAttr);
      }
    }
  }

  void applyInlineFormat(quill.Attribute attribute) {
    if (activeBlockIndex.value < 0 || activeBlockIndex.value >= blocks.length) return;
    final block = blocks[activeBlockIndex.value];
    final controller = quillControllers[block.id];
    if (controller != null) {
      controller.formatSelection(attribute);
      // Force update attributes after applying
      _updateActiveAttributes(controller);
    }
  }

  void onUpdateChecklistItem(int blockIndex, int itemIndex, String text) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return;
    final block = blocks[blockIndex];
    if (block is! ChecklistBlock || itemIndex < 0 || itemIndex >= block.items.length) return;

    final items = List<ChecklistItem>.from(block.items);
    final oldItem = items[itemIndex];
    if (oldItem.text == text) return;

    items[itemIndex] = ChecklistItem(id: oldItem.id, text: text, checked: oldItem.checked);
    blocks[blockIndex] = ChecklistBlock(id: block.id, items: items);
  }

  void addChecklistItem(int blockIndex) {
    if (blockIndex < 0 || blockIndex >= blocks.length || isReadOnly.value) return;
    _recordHistory();
    final block = blocks[blockIndex];
    if (block is! ChecklistBlock) return;

    final items = List<ChecklistItem>.from(block.items);
    items.add(ChecklistItem(id: _generateBlockId(), text: ''));
    blocks[blockIndex] = ChecklistBlock(id: block.id, items: items);
  }

  void deleteChecklistItem(int blockIndex, int itemIndex) {
    if (blockIndex < 0 || blockIndex >= blocks.length || isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is! ChecklistBlock || block.items.length <= 1) return;
    _recordHistory();

    final items = List<ChecklistItem>.from(block.items);
    items.removeAt(itemIndex);
    blocks[blockIndex] = ChecklistBlock(id: block.id, items: items);
  }

  void toggleChecklistItem(int blockIndex, int itemIndex) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return;
    _recordHistory();
    final block = blocks[blockIndex];
    if (block is! ChecklistBlock || itemIndex < 0 || itemIndex >= block.items.length) return;

    final items = List<ChecklistItem>.from(block.items);
    final oldItem = items[itemIndex];
    items[itemIndex] = ChecklistItem(id: oldItem.id, text: oldItem.text, checked: !oldItem.checked);
    blocks[blockIndex] = ChecklistBlock(id: block.id, items: items);
  }

  void addTextBlock({String style = 'body'}) {
    if (isReadOnly.value) return;
    _recordHistory();
    _insertBlock(TextBlock(id: _generateBlockId(), text: '', style: style));
  }

  void addChecklistBlock() {
    if (isReadOnly.value) return;
    _recordHistory();
    
    final newId = _generateBlockId();
    final itemId = _generateBlockId();
    
    _insertBlock(ChecklistBlock(
      id: newId, 
      items: [ChecklistItem(id: itemId, text: '')]
    ));
    
    // Logic to request focus could be added here if we had focus nodes
  }

  void addTableBlock() {
    if (isReadOnly.value) return;
    _recordHistory();
    
    _insertBlock(TableBlock(id: _generateBlockId(), rows: [['', ''], ['', '']]));
    
    // We add a text block after table for easier navigation
    addTextBlock();
  }

  Future<void> addAttachment(ImageSource source, {bool isVideo = false}) async {
    if (isReadOnly.value) return;
    try {
      final XFile? file = isVideo ? await _picker.pickVideo(source: source) : await _picker.pickImage(source: source, imageQuality: 90);
      if (file == null || currentNote.value == null) return;

      if (!File(file.path).existsSync()) {
        Get.snackbar('Error', 'The selected file could not be found', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      _recordHistory();
      _insertBlock(AttachmentBlock(id: _generateBlockId(), attachmentId: 0, displayName: file.name, localPath: file.path, url: null));
      blocks.refresh();
      addTextBlock();
    } catch (e, s) {
      _handleError('Could not add attachment', e, s);
    }
  }

  void updateAttachmentImage(int blockIndex, String editedPath) {
    if (isReadOnly.value || blockIndex < 0 || blockIndex >= blocks.length) return;
    final block = blocks[blockIndex];
    if (block is! AttachmentBlock || !File(editedPath).existsSync()) return;

    _recordHistory();
    blocks[blockIndex] = AttachmentBlock(id: block.id, attachmentId: 0, displayName: '${block.id}_edited.png', localPath: editedPath, url: block.url);
    blocks.refresh();
  }

  void updateTableCell(int blockIndex, int rowIndex, int colIndex, String value) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return;
    final block = blocks[blockIndex];
    if (block is TableBlock) {
      final rows = List<List<String>>.from(block.rows.map((r) => List<String>.from(r)));
      if (rows[rowIndex][colIndex] == value) return;
      rows[rowIndex][colIndex] = value;
      blocks[blockIndex] = TableBlock(id: block.id, rows: rows);
    }
  }

  void addTableRow(int blockIndex) {
    if (blockIndex < 0 || blockIndex >= blocks.length || isReadOnly.value) return;
    _recordHistory();
    final block = blocks[blockIndex];
    if (block is TableBlock) {
      final rows = List<List<String>>.from(block.rows.map((r) => List<String>.from(r)));
      final colCount = rows.isNotEmpty ? rows[0].length : 2;
      rows.add(List.generate(colCount, (_) => ''));
      blocks[blockIndex] = TableBlock(id: block.id, rows: rows);
    }
  }

  void addTableColumn(int blockIndex) {
    if (blockIndex < 0 || blockIndex >= blocks.length || isReadOnly.value) return;
    _recordHistory();
    final block = blocks[blockIndex];
    if (block is TableBlock) {
      final rows = List<List<String>>.from(block.rows.map((r) => List<String>.from(r)));
      for (var row in rows) { row.add(''); }
      blocks[blockIndex] = TableBlock(id: block.id, rows: rows);
    }
  }

  void updateDrawing(int blockIndex, String localPath) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return;
    final block = blocks[blockIndex];
    if (block is DrawingBlock) {
      blocks[blockIndex] = DrawingBlock(id: block.id, localPath: localPath);
    }
  }

  void deleteBlock(int index) {
    if (index < 0 || index >= blocks.length || isReadOnly.value) return;
    _recordHistory();
    blocks.removeAt(index);
    blocks.refresh();
  }

  // --- Persistence ---

  Future<void> saveNote() async {
    if (currentNote.value == null || isSaving.value || isReadOnly.value) return;
    
    // Hide keyboard and remove focus to ensure all text is synced
    Get.focusScope?.unfocus();
    
    isSaving.value = true;
    try {
      // 1. Sync data from controllers to the blocks list
      _syncTextBlocks();
      
      String finalTitle = titleController.text.trim();
      if (finalTitle.isEmpty) {
        finalTitle = _generateFallbackTitle();
        titleController.text = finalTitle;
      }

      if (kDebugMode) debugPrint("[NOTE DEBUG] PRE-SAVE Title: $finalTitle, Blocks: ${blocks.length}");

      // 2. First Save: Send Title and serialized Text content to server
      final savedNote = await _noteService.saveNote(
        currentNote.value!.folderId, 
        finalTitle, 
        noteId: currentNote.value!.id,
        content: blocks.toList(), // Use toList() to send a static snapshot
      );
      
      final confirmedNoteId = savedNote.id;
      currentNote.value = savedNote;

      // 3. Attachment Handling: If there are new local images, upload them
      bool hasNewAttachments = blocks.any((b) => b is AttachmentBlock && b.attachmentId == 0 && b.localPath != null);
      if (hasNewAttachments) {
        if (kDebugMode) debugPrint("[NOTE DEBUG] Starting attachment uploads for NoteId: $confirmedNoteId");
        
        await _handleAttachments(confirmedNoteId);
        
        // 4. Final Sync: Update the server with the new Attachment URLs in the ContentJson
        if (kDebugMode) debugPrint("[NOTE DEBUG] Final sync after uploads");
        await _noteService.saveNote(
          currentNote.value!.folderId, 
          finalTitle, 
          noteId: confirmedNoteId, 
          content: blocks.toList()
        );
      }
      
      Get.back(result: true); // Return to list view and trigger refresh
      Get.snackbar("Success", "Note saved successfully", 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.1),
      );
    } catch (e, s) {
      _handleError('Failed to save note. Please check your connection.', e, s);
    } finally {
      isSaving.value = false;
    }
  }

  String _generateFallbackTitle() {
    for (final block in blocks) {
      if (block is TextBlock && block.text.isNotEmpty) {
        String plainText = block.text;
        // Simple extraction for Quill Delta JSON
        if (plainText.contains('"insert"')) {
          try {
            final matches = RegExp(r'"insert":"([^"]+)"').allMatches(plainText);
            plainText = matches.map((m) => m.group(1)).join(' ');
          } catch (_) {}
        }
        final trimmed = plainText.trim().replaceAll('\n', ' ');
        if (trimmed.isNotEmpty) {
          return trimmed.length > 30 ? '${trimmed.substring(0, 27)}...' : trimmed;
        }
      }
    }
    return "Untitled Note";
  }

  Future<void> _handleAttachments(int noteId) async {
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block is! AttachmentBlock || block.attachmentId != 0 || block.localPath == null || block.localPath!.isEmpty) continue;
      
      try {
        final result = await _noteService.uploadAttachment(noteId, block.localPath!, block.id, i);
        final uploadedPath = _getUploadValue(result, ['Url', 'url', 'FileUrl', 'fileUrl', 'FilePath', 'filePath', 'Path', 'path']);
        final uploadedId = _getUploadValue(result, ['AttachmentId', 'attachmentId', 'Id', 'id']);
        final fullUrl = _buildAttachmentUrl(uploadedPath);

        if (fullUrl != null) {
          blocks[i] = AttachmentBlock(id: block.id, attachmentId: int.tryParse(uploadedId?.toString() ?? '') ?? 0, displayName: block.displayName, url: fullUrl, localPath: null);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to upload attachment at index $i: $e');
      }
    }
  }

  // --- Actions ---

  void undo() {
    if (_history.isEmpty || isReadOnly.value) return;
    
    // Capture current state to redo stack before undoing
    _syncTextBlocks();
    _redoStack.add(blocks.map((b) => b).toList());
    
    final lastState = _history.removeLast();
    blocks.assignAll(lastState);
    _restoreBlockControllers(lastState);
  }

  void redo() {
    if (_redoStack.isEmpty || isReadOnly.value) return;

    // Capture current state to history before redoing
    _syncTextBlocks();
    _history.add(blocks.map((b) => b).toList());

    final nextState = _redoStack.removeLast();
    blocks.assignAll(nextState);
    _restoreBlockControllers(nextState);
  }

  void toggleFormatPanel() {
    if (isReadOnly.value) return;
    isFormatPanelVisible.value = !isFormatPanelVisible.value;
    if (isFormatPanelVisible.value) {
      isSearchVisible.value = false; // Hide search if formatting
    }
  }

  void updateActiveBlockStyle(String style) {
    if (activeBlockIndex.value >= 0 && activeBlockIndex.value < blocks.length) {
      updateTextBlockStyle(activeBlockIndex.value, style);
      currentBlockStyle.value = style;
    }
  }

  void toggleSearch() {
    isSearchVisible.value = !isSearchVisible.value;
    if (isSearchVisible.value) {
      searchFocusNode.requestFocus();
    } else {
      searchQuery.value = "";
      searchFocusNode.unfocus();
    }
  }

  Future<void> togglePin() async {
    final note = currentNote.value;
    if (note == null || note.id == 0) return;
    try {
      final newState = !isPinned.value;
      await _noteService.updateNoteState(note.id, isPinned: newState);
      isPinned.value = newState;
      Get.snackbar("Success", newState ? "Note Pinned" : "Note Unpinned", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Failed to update pin status");
    }
  }

  Future<void> toggleArchive() async {
    final note = currentNote.value;
    if (note == null || note.id == 0) return;
    try {
      final newState = !isArchived.value;
      await _noteService.updateNoteState(note.id, isArchived: newState);
      isArchived.value = newState;
      Get.snackbar("Success", newState ? "Note Archived" : "Note Unarchived", snackPosition: SnackPosition.BOTTOM);
      if (newState) Get.back(result: true);
    } catch (e) {
      Get.snackbar("Error", "Failed to update archive status");
    }
  }

  Future<void> toggleLock() async {
    final note = currentNote.value;
    if (note == null || note.id == 0) return;
    try {
      final newState = !isLocked.value;
      await _noteService.updateNoteState(note.id, isLocked: newState);
      isLocked.value = newState;
      Get.snackbar("Success", newState ? "Note Locked" : "Note Unlocked",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Failed to update lock status");
    }
  }

  Future<void> deleteNote() async {
    final note = currentNote.value;
    if (note == null || note.id == 0) return;

    Get.dialog(AlertDialog(
      title: const Text("Delete Note?"),
      content: const Text("This note will be moved to Recently Deleted."),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
        TextButton(
          onPressed: () async {
            try {
              await _noteService.deleteRestoreNote(note.id, true);
              Get.back(); Get.back(result: true);
              Get.snackbar("Success", "Note moved to trash",
                  snackPosition: SnackPosition.BOTTOM);
            } catch (e) {
              Get.snackbar("Error", "Could not delete note. Please try again.");
            }
          },
          child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ));
  }

  Future<void> moveNote() async {
    final note = currentNote.value;
    if (note == null || note.id == 0) return;
    try {
      final folderRes = await _folderService.getFolders();
      if (folderRes.folders.isEmpty) { Get.snackbar("Info", "No destination folders available"); return; }

      Get.bottomSheet(NoteMoveFolderModal(
        folders: folderRes.folders,
        currentFolderId: note.folderId,
        onFolderSelected: (folder) async {
          Get.back();
          try {
            _syncTextBlocks();
            await _noteService.saveNote(folder.id, titleController.text.trim(),
                noteId: note.id, content: blocks);
            Get.back(result: true);
            Get.snackbar("Success", "Moved note to ${folder.name}", snackPosition: SnackPosition.BOTTOM);
          } catch (e) { Get.snackbar("Error", "Failed to move note"); }
        },
      ), isScrollControlled: true);
    } catch (e) { Get.snackbar("Error", "Could not fetch folders"); }
  }

  void shareNote() {
    _syncTextBlocks();
    String content = "${titleController.text}\n\n";
    for (final block in blocks) {
      if (block is TextBlock) { content += "${block.text}\n"; }
      else if (block is ChecklistBlock) { for (final item in block.items) { content += "[${item.checked ? 'x' : ' '}] ${item.text}\n"; } }
    }
    Get.dialog(AlertDialog(
      title: const Text("Share Note"),
      content: SingleChildScrollView(child: Text(content)),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Close")),
        TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: content)); Get.back();
          Get.snackbar("Success", "Content copied",
            snackPosition: SnackPosition.BOTTOM); }, child: const Text("Copy Text")),
      ],
    ));
  }

  // --- Private Helpers ---

  void _syncTextBlocks() {
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block is TextBlock) {
        final qc = quillControllers[block.id];
        if (qc != null) {
          final json = jsonEncode(qc.document.toDelta().toJson());
          blocks[i] = TextBlock(id: block.id, text: json, style: block.style);
        } else {
          final tc = blockControllers[block.id];
          if (tc != null) blocks[i] = TextBlock(id: block.id, text: tc.text, style: block.style);
        }
      } else if (block is ChecklistBlock) {
        final items = List<ChecklistItem>.from(block.items);
        bool changed = false;
        for (int j = 0; j < items.length; j++) {
          final tc = blockControllers['${block.id}_${items[j].id}'];
          if (tc != null && tc.text != items[j].text) {
            items[j] = ChecklistItem(id: items[j].id, text: tc.text, checked: items[j].checked);
            changed = true;
          }
        }
        if (changed) blocks[i] = ChecklistBlock(id: block.id, items: items);
      } else if (block is TableBlock) {
        final rows = List<List<String>>.from(block.rows.map((r) => List<String>.from(r)));
        bool changed = false;
        for (int r = 0; r < rows.length; r++) {
          for (int c = 0; c < rows[r].length; c++) {
            final tc = blockControllers['table_${block.id}_${r}_$c'];
            if (tc != null && tc.text != rows[r][c]) {
              rows[r][c] = tc.text;
              changed = true;
            }
          }
        }
        if (changed) blocks[i] = TableBlock(id: block.id, rows: rows);
      }
    }
  }

  void _recordHistory() {
    _syncTextBlocks();
    final snapshot = blocks.map((b) => b).toList();
    _history.add(snapshot);
    if (_history.length > _maxHistory) _history.removeAt(0);
    
    // Clear redo stack whenever a new action is performed
    _redoStack.clear();
  }

  void _restoreBlockControllers(List<NoteBlock> state) {
    for (final block in state) {
      if (block is TextBlock) {
        blockControllers[block.id]?.text = block.text;
      } else if (block is ChecklistBlock) {
        for (final item in block.items) {
          blockControllers['${block.id}_${item.id}']?.text = item.text;
        }
      }
    }
  }

  void _clearControllers() {
    for (final controller in blockControllers.values) { controller.dispose(); }
    blockControllers.clear();
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

  void _handleError(String msg, dynamic e, StackTrace s) {
    if (e is dio.DioException && e.response?.statusCode == 404) {
      Get.snackbar('Error', 'Note not found. It may have been deleted.',
          snackPosition: SnackPosition.BOTTOM);
      Future.delayed(const Duration(seconds: 1), () => Get.back());
    } else {
      Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM);
    }
    if (kDebugMode) {
      debugPrint('$msg: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  dynamic _getUploadValue(dynamic result, List<String> keys) {
    if (result is! Map) return null;
    for (final key in keys) { final v = result[key]; if (v != null && v.toString().isNotEmpty) return v; }
    final nested = result['data'] ?? result['Data'] ?? result['result'] ?? result['Result'];
    if (nested is Map) { for (final key in keys) { final v = nested[key]; if (v != null && v.toString().isNotEmpty) return v; } }
    return null;
  }

  String? _buildAttachmentUrl(dynamic value) {
    if (value == null) return null;
    String p = value.toString().trim().replaceAll('\\', '/');
    if (p.isEmpty) return null;
    if (p.startsWith('~/')) p = p.substring(2);
    final u = Uri.tryParse(p);
    if (u != null && u.hasScheme) return u.toString();
    return Uri.parse('https://note.piisiit.com/').resolve(p).toString();
  }

  int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
  String _generateBlockId() => DateTime.now().microsecondsSinceEpoch.toString();
}
