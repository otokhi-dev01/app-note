import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/note_model.dart';
import '../../data/services/note_service.dart';

class NoteDetailController extends GetxController {
  final _noteService = Get.find<NoteService>();
  final _picker = ImagePicker();

  final currentNote = Rxn<NoteModel>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isReadOnly = false.obs;

  final titleController = TextEditingController();
  final blocks = <NoteBlock>[].obs;
  int activeBlockIndex = -1;
  final Map<String, TextEditingController> blockControllers = {};

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (kDebugMode) debugPrint("NoteDetailController.onInit with args: $args (Type: ${args.runtimeType})");

    if (args is Map) {
      final int? noteId = args['noteId'];
      final int? folderId = args['folderId'];
      isReadOnly.value = args['isDeleted'] ?? false;
      
      if (noteId != null && noteId != 0) {
        fetchNoteDetail(noteId);
      } else if (folderId != null) {
        _initNewNote(folderId);
      } else {
        if (kDebugMode) debugPrint("NoteDetailController: Invalid Map arguments, closing.");
        Get.back();
        Get.snackbar("Error", "Invalid navigation arguments");
      }
    } else {
      if (kDebugMode) debugPrint("NoteDetailController: Arguments are not a Map, closing.");
      Get.back();
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    for (var controller in blockControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> fetchNoteDetail(int id) async {
    isLoading.value = true;
    try {
      if (kDebugMode) debugPrint("fetchNoteDetail START for NoteId: $id");
      final note = await _noteService.getNoteDetail(id);
      
      if (kDebugMode) debugPrint("fetchNoteDetail SUCCESS for NoteId: $id");
      currentNote.value = note;
      titleController.text = note.title;
      
      // Clear old controllers
      for (var c in blockControllers.values) {
        c.dispose();
      }
      blockControllers.clear();
      
      blocks.assignAll(note.content);
      
      if (blocks.isEmpty) {
        addTextBlock();
      }
    } catch (e) {
      if (kDebugMode) debugPrint("fetchNoteDetail CATCH ERROR for NoteId: $id: $e");
      Get.snackbar("Error", "Could not load note detail");
    } finally {
      if (kDebugMode) debugPrint("fetchNoteDetail FINALLY (loading = false) for NoteId: $id");
      isLoading.value = false;
    }
  }

  void _initNewNote(int folderId) {
    currentNote.value = NoteModel(id: 0, folderId: folderId, title: "", folderName: "");
    titleController.clear();
    blocks.clear();
    addTextBlock();
    isLoading.value = false;
  }

  TextEditingController getTextController(String blockId, String initialText) {
    if (!blockControllers.containsKey(blockId)) {
      blockControllers[blockId] = TextEditingController(text: initialText);
    }
    return blockControllers[blockId]!;
  }

  Future<void> saveNote() async {
    if (currentNote.value == null || isSaving.value || isReadOnly.value) return;
    
    isSaving.value = true;
    
    // Sync text controllers back to blocks
    for (int i = 0; i < blocks.length; i++) {
      if (blocks[i] is TextBlock) {
        final controller = blockControllers[blocks[i].id];
        if (controller != null) {
          blocks[i] = TextBlock(
            id: blocks[i].id, 
            text: controller.text,
            style: (blocks[i] as TextBlock).style,
          );
        }
      }
    }

    final int originalId = currentNote.value!.id;
    final int folderId = currentNote.value!.folderId;
    if (kDebugMode) {
      debugPrint("[NOTE DEBUG] SAVE FLOW START");
      debugPrint("[NOTE DEBUG] CURRENT NOTE ID: $originalId");
      debugPrint("[NOTE DEBUG] FOLDER ID: $folderId");
    }
    
    try {
      // 1. Save Metadata first
      final savedNote = await _noteService.saveNote(
        folderId, 
        titleController.text,
        noteId: originalId,
      );
      
      final int confirmedNoteId = savedNote.id;
      if (kDebugMode) debugPrint("[NOTE DEBUG] STEP 1: Metadata Saved. Confirmed ID: $confirmedNoteId");
      currentNote.value = savedNote;

      // 2. Upload any unsaved attachments
      for (int i = 0; i < blocks.length; i++) {
        final block = blocks[i];
        if (block is AttachmentBlock && block.attachmentId == 0 && block.localPath != null) {
          try {
            if (kDebugMode) debugPrint("[NOTE DEBUG] STEP 2: Uploading attachment for block: ${block.id}");
            final result = await _noteService.uploadAttachment(
              confirmedNoteId,
              block.localPath!,
              block.id,
              i,
            );

            // Update block with SERVER data
            if (kDebugMode) debugPrint("[NOTE DEBUG] UPLOAD RESULT KEYS: ${result.keys.toList()}");
            
            blocks[i] = AttachmentBlock(
              id: block.id,
              attachmentId: int.tryParse((result['AttachmentId'] ?? result['attachmentId'] ?? result['id'] ?? result['Id'] ?? 0).toString()) ?? 0,
              displayName: block.displayName,
              url: result['Url'] ?? result['url'] ?? result['FilePath'] ?? result['filePath'],
              localPath: null,
            );
            if (kDebugMode) debugPrint("[NOTE DEBUG] UPLOAD SUCCESS: New AttachmentId: ${(blocks[i] as AttachmentBlock).attachmentId}");
          } catch (e) {
            debugPrint("Failed to upload attachment: $e");
          }
        }
      }

      // 3. Save Final Content
      if (kDebugMode) debugPrint("[NOTE DEBUG] STEP 3: Saving final content blocks for $confirmedNoteId");
      await _noteService.saveContent(confirmedNoteId, folderId, titleController.text, blocks);
      
      if (kDebugMode) debugPrint("[NOTE DEBUG] SAVE COMPLETE - NoteId: $confirmedNoteId");
      isSaving.value = false;
      Get.back(result: true);
    } catch (e) {
      isSaving.value = false;
      if (kDebugMode) debugPrint("[NOTE DEBUG] SAVE FATAL ERROR: $e");
      Get.snackbar("Error", "Failed to save note: ${e.toString()}");
    }
  }

  void updateTextBlock(int index, String text) {}

  void onUpdateChecklistItem(int blockIndex, int itemIndex, String text) {
    if (blocks[blockIndex] is ChecklistBlock) {
      final block = blocks[blockIndex] as ChecklistBlock;
      block.items[itemIndex] = ChecklistItem(
        id: block.items[itemIndex].id,
        text: text,
        checked: block.items[itemIndex].checked,
      );
      blocks[blockIndex] = ChecklistBlock(id: block.id, items: block.items);
    }
  }

  void toggleChecklistItem(int blockIndex, int itemIndex) {
    if (blocks[blockIndex] is ChecklistBlock) {
      final block = blocks[blockIndex] as ChecklistBlock;
      final item = block.items[itemIndex];
      block.items[itemIndex] = ChecklistItem(id: item.id, text: item.text, checked: !item.checked);
      blocks[blockIndex] = ChecklistBlock(id: block.id, items: block.items);
    }
  }

  void addTextBlock({String style = 'body'}) {
    if (isReadOnly.value) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final block = TextBlock(id: id, text: "", style: style);
    
    if (activeBlockIndex >= 0 && activeBlockIndex < blocks.length) {
      blocks.insert(activeBlockIndex + 1, block);
      activeBlockIndex++;
    } else {
      blocks.add(block);
      activeBlockIndex = blocks.length - 1;
    }
  }

  void addChecklistBlock() {
    if (isReadOnly.value) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final block = ChecklistBlock(id: id, items: [
      ChecklistItem(id: "1", text: "")
    ]);

    if (activeBlockIndex >= 0 && activeBlockIndex < blocks.length) {
      blocks.insert(activeBlockIndex + 1, block);
      activeBlockIndex++;
    } else {
      blocks.add(block);
      activeBlockIndex = blocks.length - 1;
    }
  }

  Future<void> addAttachment(ImageSource source, {bool isVideo = false}) async {
    if (isReadOnly.value) return;
    try {
      XFile? file;
      if (isVideo) {
        file = await _picker.pickVideo(source: source);
      } else {
        file = await _picker.pickImage(source: source);
      }

      if (file != null && currentNote.value != null) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        final block = AttachmentBlock(
          id: id,
          attachmentId: 0,
          displayName: file.name,
          localPath: file.path,
        );
        
        if (activeBlockIndex >= 0 && activeBlockIndex < blocks.length) {
          blocks.insert(activeBlockIndex + 1, block);
          activeBlockIndex++;
        } else {
          blocks.add(block);
          activeBlockIndex = blocks.length - 1;
        }
        
        addTextBlock();
      }
    } catch (e) {
      Get.snackbar("Error", "Could not add attachment");
    }
  }

  void addTableBlock() {
    if (isReadOnly.value) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final block = TableBlock(id: id, rows: [
      ["", ""],
      ["", ""]
    ]);

    if (activeBlockIndex >= 0 && activeBlockIndex < blocks.length) {
      blocks.insert(activeBlockIndex + 1, block);
      activeBlockIndex++;
    } else {
      blocks.add(block);
      activeBlockIndex = blocks.length - 1;
    }
    addTextBlock();
  }

  void addDrawingBlock() {
    if (isReadOnly.value) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final block = DrawingBlock(id: id);

    if (activeBlockIndex >= 0 && activeBlockIndex < blocks.length) {
      blocks.insert(activeBlockIndex + 1, block);
      activeBlockIndex++;
    } else {
      blocks.add(block);
      activeBlockIndex = blocks.length - 1;
    }
    addTextBlock();
  }

  void updateTextBlockStyle(int index, String style) {
    if (isReadOnly.value) return;
    if (blocks[index] is TextBlock) {
      final oldBlock = blocks[index] as TextBlock;
      blocks[index] = TextBlock(
        id: oldBlock.id,
        text: oldBlock.text,
        style: style,
      );
    }
  }
}
