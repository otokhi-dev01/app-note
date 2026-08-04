import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/note_model.dart';
import '../../data/models/folder_model.dart';
import '../../data/services/folder_service.dart';
import '../../data/services/note_service.dart';
import 'widgets/note_move_folder_modal.dart';

class NoteController extends GetxController {
  final _noteService = Get.find<NoteService>();
  final _picker = ImagePicker();

  final notes = <NoteModel>[].obs;
  final archivedNotes = <NoteModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = "".obs;

  // Edit and selection mode for list view
  final isEditing = false.obs;
  final selectedNoteIds = <int>{}.obs;
  
  // For Detail View
  final currentNote = Rxn<NoteModel>();
  final titleController = TextEditingController();
  final blocks = <NoteBlock>[].obs;
  
  // Track currently focused block index for insertions
  int activeBlockIndex = -1;
  
  // Map to keep track of text controllers for each block to prevent focus loss
  final Map<String, TextEditingController> blockControllers = {};

  void toggleEditing() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      selectedNoteIds.clear();
    }
  }

  void toggleSelectNote(int id) {
    if (selectedNoteIds.contains(id)) {
      selectedNoteIds.remove(id);
    } else {
      selectedNoteIds.add(id);
    }
  }

  Future<void> deleteSelectedNotes(int folderId) async {
    final targets = selectedNoteIds.isNotEmpty
        ? selectedNoteIds.toList()
        : notes.map((n) => n.id).toList();

    if (targets.isEmpty) return;

    try {
      for (final id in targets) {
        await _noteService.deleteRestoreNote(id, true);
      }
      selectedNoteIds.clear();
      isEditing.value = false;
      await fetchNotes(folderId: folderId);
      Get.snackbar("Success", "Notes moved to Recently Deleted",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Could not delete notes");
    }
  }

  Future<void> moveSelectedNotes(BuildContext context, int currentFolderId) async {
    final targets = selectedNoteIds.isNotEmpty
        ? selectedNoteIds.toList()
        : notes.map((n) => n.id).toList();

    if (targets.isEmpty) return;

    try {
      final folderRes = await Get.find<FolderService>().getFolders();
      final allFolders = folderRes.folders;

      if (allFolders.isEmpty) {
        Get.snackbar("Info", "No destination folders available");
        return;
      }

      Get.bottomSheet(
        NoteMoveFolderModal(
          folders: allFolders,
          currentFolderId: currentFolderId,
          onFolderSelected: (folder) async {
            Get.back();
            try {
              for (final noteId in targets) {
                final note = notes.firstWhereOrNull((n) => n.id == noteId);
                if (note != null) {
                  await _noteService.saveNote(
                    folder.id,
                    note.title,
                    noteId: note.id,
                  );
                }
              }
              selectedNoteIds.clear();
              isEditing.value = false;
              await fetchNotes(folderId: currentFolderId);
              Get.snackbar(
                "Success",
                "Moved notes to ${folder.name}",
                snackPosition: SnackPosition.BOTTOM,
              );
            } catch (e) {
              Get.snackbar("Error", "Failed to move notes");
            }
          },
        ),
        isScrollControlled: true,
      );
    } catch (e) {
      Get.snackbar("Error", "Could not fetch folders");
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args.containsKey('noteId')) {
      if (args['noteId'] != 0) {
        fetchNoteDetail(args['noteId']);
      } else {
        _initNewNote(args['folderId']);
      }
    } else if (args is FolderModel) {
      fetchNotes(folderId: args.id);
    } else {
      fetchNotes();
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

  Future<void> fetchNotes({int? folderId}) async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final response = await _noteService.getNotes(folderId: folderId);
      
      notes.assignAll(_sortNotes(response.notes));
      archivedNotes.assignAll(_sortNotes(response.archive));
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "Unable to load notes. Please check your connection.";
      Get.snackbar("Error", "Could not load notes");
    } finally {
      isLoading.value = false;
    }
  }

  List<NoteModel> _sortNotes(List<NoteModel> list) {
    list.sort((a, b) {
      // 1. Pinned notes first
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      // 2. UpdatedAt descending (newest first)
      final dateA = a.updatedAt ?? DateTime(0);
      final dateB = b.updatedAt ?? DateTime(0);
      return dateB.compareTo(dateA);
    });
    return list;
  }

  Future<void> fetchNoteDetail(int id) async {
    isLoading.value = true;
    try {
      final note = await _noteService.getNoteDetail(id);
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
      Get.snackbar("Error", "Could not load note detail");
    } finally {
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
    if (currentNote.value == null) return;
    
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
    
    try {
      if (currentNote.value!.id == 0) {
        await _noteService.saveNote(currentNote.value!.folderId, titleController.text);
      } else {
        await _noteService.saveContent(currentNote.value!.id, titleController.text, blocks);
      }
      Get.back(result: true);
    } catch (e) {
      Get.snackbar("Error", "Failed to save note");
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

        if (currentNote.value!.id != 0) {
          await _noteService.uploadAttachment(
            currentNote.value!.id,
            file.path,
            id,
            blocks.length,
          );
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Could not add attachment");
    }
  }

  void addTableBlock() {
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
    if (blocks[index] is TextBlock) {
      final oldBlock = blocks[index] as TextBlock;
      blocks[index] = TextBlock(
        id: oldBlock.id,
        text: oldBlock.text,
        style: style,
      );
    }
  }

  void toggleViewMode() {
    Get.snackbar("Info", "Gallery View coming soon");
  }

  void updateSorting(String criteria) {
    Get.snackbar("Info", "Sorting by $criteria");
  }

  void toggleDateGrouping() {
    Get.snackbar("Info", "Date grouping toggled");
  }

  void viewAllAttachments() {
    Get.snackbar("Info", "Viewing all attachments");
  }
}
