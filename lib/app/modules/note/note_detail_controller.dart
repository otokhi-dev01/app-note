import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/note_model.dart';
import '../../data/services/note_service.dart';

class NoteDetailController extends GetxController {
  final NoteService _noteService = Get.find<NoteService>();
  final ImagePicker _picker = ImagePicker();

  final currentNote = Rxn<NoteModel>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isReadOnly = false.obs;
  final isPinned = false.obs;
  final isArchived = false.obs;

  final titleController = TextEditingController();
  final blocks = <NoteBlock>[].obs;
  final Map<String, TextEditingController> blockControllers = {};
  
  // History for undo
  final _history = <List<NoteBlock>>[];
  static const int _maxHistory = 20;

  int activeBlockIndex = -1;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;

    if (kDebugMode) {
      debugPrint('NoteDetailController.onInit with args: $args');
    }

    if (args is Map) {
      final noteId = _toInt(args['noteId']);
      final folderId = _toInt(args['folderId']);

      isReadOnly.value = args['isDeleted'] == true;

      if (noteId != null && noteId != 0) {
        fetchNoteDetail(noteId);
      } else if (folderId != null) {
        _initNewNote(folderId);
      } else {
        Get.back();
      }
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    titleController.dispose();

    for (final controller in blockControllers.values) {
      controller.dispose();
    }

    blockControllers.clear();
    super.onClose();
  }

  Future<void> fetchNoteDetail(int id) async {
    isLoading.value = true;

    try {
      final note = await _noteService.getNoteDetail(id);

      currentNote.value = note;
      titleController.text = note.title;
      isPinned.value = note.isPinned;
      isArchived.value = note.isArchived;

      for (final controller in blockControllers.values) {
        controller.dispose();
      }

      blockControllers.clear();
      blocks.assignAll(note.content);
      _history.clear(); // Clear history on load

      if (blocks.isEmpty && !isReadOnly.value) {
        addTextBlock();
      }
    } catch (error, stackTrace) {
      Get.snackbar(
        'Error',
        'Could not load note detail',
        snackPosition: SnackPosition.BOTTOM,
      );

      if (kDebugMode) {
        debugPrint('Could not load note detail: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _initNewNote(int folderId) {
    currentNote.value = NoteModel(
      id: 0,
      folderId: folderId,
      title: '',
      folderName: '',
    );

    isPinned.value = false;
    isArchived.value = false;
    titleController.clear();
    blocks.clear();
    _history.clear();
    addTextBlock();
    isLoading.value = false;
  }

  TextEditingController getTextController(
      String blockId,
      String initialText,
      ) {
    return blockControllers.putIfAbsent(
      blockId,
          () => TextEditingController(text: initialText),
    );
  }

  Future<void> saveNote() async {
    if (currentNote.value == null ||
        isSaving.value ||
        isReadOnly.value) {
      return;
    }

    isSaving.value = true;

    try {
      _syncTextBlocks();

      final savedNote = await _noteService.saveNote(
        currentNote.value!.folderId,
        titleController.text.trim(),
        noteId: currentNote.value!.id,
      );

      final confirmedNoteId = savedNote.id;
      currentNote.value = savedNote;

      for (int index = 0; index < blocks.length; index++) {
        final block = blocks[index];

        if (block is! AttachmentBlock ||
            block.attachmentId != 0 ||
            block.localPath == null ||
            block.localPath!.trim().isEmpty) {
          continue;
        }

        final localPath = block.localPath!.trim();
        final localFile = File(localPath);

        if (!localFile.existsSync()) {
          if (kDebugMode) {
            debugPrint('Attachment file does not exist: $localPath');
          }
          continue;
        }

        try {
          final result = await _noteService.uploadAttachment(
            confirmedNoteId,
            localPath,
            block.id,
            index,
          );

          if (kDebugMode) {
            debugPrint('Attachment upload response: $result');
          }

          final uploadedPath = _getUploadValue(
            result,
            const [
              'Url',
              'url',
              'FileUrl',
              'fileUrl',
              'FilePath',
              'filePath',
              'Path',
              'path',
            ],
          );

          final uploadedId = _getUploadValue(
            result,
            const [
              'AttachmentId',
              'attachmentId',
              'Id',
              'id',
            ],
          );

          final fullUrl = _buildAttachmentUrl(uploadedPath);
          final attachmentId =
              int.tryParse(uploadedId?.toString() ?? '') ?? 0;

          if (fullUrl == null || fullUrl.isEmpty) {
            if (kDebugMode) {
              debugPrint(
                'Upload response did not contain a valid image URL.',
              );
            }

            // Keep the local path so the image remains visible.
            continue;
          }

          blocks[index] = AttachmentBlock(
            id: block.id,
            attachmentId: attachmentId,
            displayName: block.displayName,
            url: fullUrl,
            localPath: null,
          );
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint('Failed to upload attachment: $error');
            debugPrintStack(stackTrace: stackTrace);
          }

          // Keep the local path when upload fails.
        }
      }

      await _noteService.saveNote(
        currentNote.value!.folderId,
        titleController.text.trim(),
        noteId: confirmedNoteId,
        content: blocks,
      );

      Get.back(result: true);
    } catch (error, stackTrace) {
      Get.snackbar(
        'Error',
        'Failed to save note',
        snackPosition: SnackPosition.BOTTOM,
      );

      if (kDebugMode) {
        debugPrint('[NOTE DEBUG] SAVE FATAL ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      isSaving.value = false;
    }
  }

  void _syncTextBlocks() {
    for (int index = 0; index < blocks.length; index++) {
      final block = blocks[index];

      if (block is! TextBlock) continue;

      final textController = blockControllers[block.id];

      if (textController != null) {
        blocks[index] = TextBlock(
          id: block.id,
          text: textController.text,
          style: block.style,
        );
      }
    }
  }

  void updateTextBlock(int index, String text) {
    if (index < 0 || index >= blocks.length) return;

    final block = blocks[index];

    if (block is TextBlock) {
      blocks[index] = TextBlock(
        id: block.id,
        text: text,
        style: block.style,
      );
    }
  }

  void onUpdateChecklistItem(
      int blockIndex,
      int itemIndex,
      String text,
      ) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return;

    final block = blocks[blockIndex];

    if (block is! ChecklistBlock ||
        itemIndex < 0 ||
        itemIndex >= block.items.length) {
      return;
    }

    // We don't save history for every character, but maybe on focused change or periodically
    // For now, just update
    final items = List<ChecklistItem>.from(block.items);
    final oldItem = items[itemIndex];

    items[itemIndex] = ChecklistItem(
      id: oldItem.id,
      text: text,
      checked: oldItem.checked,
    );

    blocks[blockIndex] = ChecklistBlock(
      id: block.id,
      items: items,
    );
  }

  void toggleChecklistItem(
      int blockIndex,
      int itemIndex,
      ) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return;
    _recordHistory();

    final block = blocks[blockIndex];

    if (block is! ChecklistBlock ||
        itemIndex < 0 ||
        itemIndex >= block.items.length) {
      return;
    }

    final items = List<ChecklistItem>.from(block.items);
    final oldItem = items[itemIndex];

    items[itemIndex] = ChecklistItem(
      id: oldItem.id,
      text: oldItem.text,
      checked: !oldItem.checked,
    );

    blocks[blockIndex] = ChecklistBlock(
      id: block.id,
      items: items,
    );
  }

  void addTextBlock({String style = 'body'}) {
    if (isReadOnly.value) return;
    _recordHistory();

    _insertBlock(
      TextBlock(
        id: _generateBlockId(),
        text: '',
        style: style,
      ),
    );
  }

  void addChecklistBlock() {
    if (isReadOnly.value) return;
    _recordHistory();

    _insertBlock(
      ChecklistBlock(
        id: _generateBlockId(),
        items: [
          ChecklistItem(
            id: _generateBlockId(),
            text: '',
          ),
        ],
      ),
    );
  }

  Future<void> addAttachment(
      ImageSource source, {
        bool isVideo = false,
      }) async {
    if (isReadOnly.value) return;

    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (file == null || currentNote.value == null) return;

      final localFile = File(file.path);

      if (!localFile.existsSync()) {
        Get.snackbar(
          'Error',
          'The selected file could not be found',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      _recordHistory();
      _insertBlock(
        AttachmentBlock(
          id: _generateBlockId(),
          attachmentId: 0,
          displayName: file.name,
          localPath: file.path,
          url: null,
        ),
      );

      blocks.refresh();
      addTextBlock();
    } catch (error, stackTrace) {
      Get.snackbar(
        'Error',
        'Could not add attachment',
        snackPosition: SnackPosition.BOTTOM,
      );

      if (kDebugMode) {
        debugPrint('Could not add attachment: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  void updateAttachmentImage(
      int blockIndex,
      String editedPath,
      ) {
    if (isReadOnly.value) return;
    if (blockIndex < 0 || blockIndex >= blocks.length) return;

    final block = blocks[blockIndex];

    if (block is! AttachmentBlock) return;

    final editedFile = File(editedPath);

    if (!editedFile.existsSync()) {
      Get.snackbar(
        'Error',
        'The edited image file could not be found',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _recordHistory();
    blocks[blockIndex] = AttachmentBlock(
      id: block.id,
      attachmentId: 0,
      displayName: '${block.id}_edited.png',
      localPath: editedPath,
      url: block.url,
    );

    blocks.refresh();
  }

  void addTableBlock() {
    if (isReadOnly.value) return;
    _recordHistory();

    _insertBlock(
      TableBlock(
        id: _generateBlockId(),
        rows: [
          ['', ''],
          ['', ''],
        ],
      ),
    );

    addTextBlock();
  }

  void addDrawingBlock() {
    if (isReadOnly.value) return;
    _recordHistory();

    _insertBlock(
      DrawingBlock(
        id: _generateBlockId(),
      ),
    );

    addTextBlock();
  }

  void updateTextBlockStyle(
      int index,
      String style,
      ) {
    if (isReadOnly.value) return;
    if (index < 0 || index >= blocks.length) return;
    _recordHistory();

    final block = blocks[index];

    if (block is TextBlock) {
      blocks[index] = TextBlock(
        id: block.id,
        text: blockControllers[block.id]?.text ?? block.text,
        style: style,
      );
    }
  }

  void deleteBlock(int index) {
    if (index < 0 || index >= blocks.length || isReadOnly.value) return;
    _recordHistory();
    blocks.removeAt(index);
    blocks.refresh();
  }

  void _insertBlock(NoteBlock block) {
    if (activeBlockIndex >= 0 &&
        activeBlockIndex < blocks.length) {
      blocks.insert(activeBlockIndex + 1, block);
      activeBlockIndex++;
    } else {
      blocks.add(block);
      activeBlockIndex = blocks.length - 1;
    }
  }

  dynamic _getUploadValue(
      dynamic result,
      List<String> keys,
      ) {
    if (result is! Map) return null;

    for (final key in keys) {
      final value = result[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    final nestedData =
        result['data'] ??
            result['Data'] ??
            result['result'] ??
            result['Result'];

    if (nestedData is Map) {
      for (final key in keys) {
        final value = nestedData[key];

        if (value != null && value.toString().trim().isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  String? _buildAttachmentUrl(dynamic value) {
    if (value == null) return null;

    String path = value.toString().trim();

    if (path.isEmpty) return null;

    path = path.replaceAll('\\', '/');

    if (path.startsWith('~/')) {
      path = path.substring(2);
    }

    final uri = Uri.tryParse(path);

    if (uri != null && uri.hasScheme) {
      return uri.toString();
    }

    return Uri.parse(
      'https://note.piisiit.com/',
    ).resolve(path).toString();
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _generateBlockId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  // --- New Logic ---

  void _recordHistory() {
    _syncTextBlocks();
    // Deep copy blocks
    final snapshot = blocks.map((b) => b).toList();
    _history.add(snapshot);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }
  }

  void undo() {
    if (_history.isEmpty || isReadOnly.value) return;

    final lastState = _history.removeLast();
    blocks.assignAll(lastState);

    // Refresh controllers
    for (final block in lastState) {
      if (block is TextBlock) {
        final controller = blockControllers[block.id];
        if (controller != null) {
          controller.text = block.text;
        }
      } else if (block is ChecklistBlock) {
        for (final item in block.items) {
          final controller = blockControllers['${block.id}_${item.id}'];
          if (controller != null) {
            controller.text = item.text;
          }
        }
      }
    }
  }

  Future<void> togglePin() async {
    final note = currentNote.value;
    if (note == null || note.id == 0) return;

    try {
      final newState = !isPinned.value;
      await _noteService.updateNoteState(note.id, isPinned: newState);
      isPinned.value = newState;
      Get.snackbar("Success", newState ? "Note Pinned" : "Note Unpinned",
          snackPosition: SnackPosition.BOTTOM);
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
      Get.snackbar("Success", newState ? "Note Archived" : "Note Unarchived",
          snackPosition: SnackPosition.BOTTOM);
      if (newState) Get.back(result: true); // Go back if archived
    } catch (e) {
      Get.snackbar("Error", "Failed to update archive status");
    }
  }

  Future<void> deleteNote() async {
    final note = currentNote.value;
    if (note == null || note.id == 0) return;

    Get.dialog(
      AlertDialog(
        title: const Text("Delete Note?"),
        content: const Text("This note will be moved to Recently Deleted."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              try {
                await _noteService.deleteRestoreNote(note.id, true);
                Get.back(); // close dialog
                Get.back(result: true); // go back to list
                Get.snackbar("Success", "Note moved to trash",
                    snackPosition: SnackPosition.BOTTOM);
              } catch (e) {
                Get.snackbar("Error", "Failed to delete note");
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void shareNote() {
    _syncTextBlocks();
    String content = "${titleController.text}\n\n";
    for (final block in blocks) {
      if (block is TextBlock) {
        content += "${block.text}\n";
      } else if (block is ChecklistBlock) {
        for (final item in block.items) {
          content += "[${item.checked ? 'x' : ' '}] ${item.text}\n";
        }
      }
    }
    
    // Since share_plus is not in pubspec, we use a dialog or clipboard for now
    Get.dialog(
      AlertDialog(
        title: const Text("Share Note"),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Close")),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Get.back();
              Get.snackbar("Success", "Content copied to clipboard",
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text("Copy Text"),
          ),
        ],
      ),
    );
  }
}
