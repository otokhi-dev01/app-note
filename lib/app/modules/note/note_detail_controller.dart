import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  final titleController = TextEditingController();
  final blocks = <NoteBlock>[].obs;
  final Map<String, TextEditingController> blockControllers = {};

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

      for (final controller in blockControllers.values) {
        controller.dispose();
      }

      blockControllers.clear();
      blocks.assignAll(note.content);

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

    titleController.clear();
    blocks.clear();
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

    final block = blocks[index];

    if (block is TextBlock) {
      blocks[index] = TextBlock(
        id: block.id,
        text: blockControllers[block.id]?.text ?? block.text,
        style: style,
      );
    }
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
}
