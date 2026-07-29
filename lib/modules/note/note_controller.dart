import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/models/note_model.dart';
import '../../data/models/content_block_model.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/unlock_vault_view.dart';
import '../home/home_controller.dart';
import '../folder/folder_controller.dart';
import 'note_list_controller.dart';

class NoteController extends GetxController {
  final NoteRepository _repository = NoteRepository();
  final _uuid = const Uuid();
  final _picker = ImagePicker();
  final note = Rxn<NoteModel>();
  final isLoading = false.obs;
  final titleController = TextEditingController();
  final blocks = <ContentBlockModel>[].obs;
  final selectedFolderId = 2.obs;
  
  // Cache controllers to prevent re-creation in build
  final blockControllers = <String, TextEditingController>{};

  @override
  void onClose() {
    for (var controller in blockControllers.values) {
      controller.dispose();
    }
    titleController.dispose();
    super.onClose();
  }

  TextEditingController getBlockController(String id, String? initialText) {
    if (!blockControllers.containsKey(id)) {
      blockControllers[id] = TextEditingController(text: initialText);
    }
    return blockControllers[id]!;
  }

  void initNote(dynamic args) async {
    if (args == null || (args is Map && !args.containsKey('noteId'))) {
      note.value = null;
      titleController.clear();
      blockControllers.clear();
      
      // If we have a folderId argument (from FolderDetailView), use it
      if (args is Map && args.containsKey('folderId')) {
        selectedFolderId.value = args['folderId'] ?? 2;
      } else {
        selectedFolderId.value = 2; // Default
      }
      
      blocks.value = [
        ContentBlockModel(id: _uuid.v4(), type: 'text', text: '')
      ];
    } else {
      final int noteId = args is int ? args : args['noteId'];
      isLoading.value = true;
      try {
        final detail = await _repository.getNoteDetail(noteId);
        if (detail != null) {
          if (detail.isLocked) {
            _showUnlockDialog(detail);
          } else {
            _loadNoteData(detail);
          }
        }
      } finally {
        isLoading.value = false;
      }
    }
  }

  void _loadNoteData(NoteModel detail) {
    note.value = detail;
    titleController.text = detail.title;
    selectedFolderId.value = detail.folderId ?? 2;
    blocks.value = detail.content ?? [
      ContentBlockModel(id: _uuid.v4(), type: 'text', text: '')
    ];
  }

  void _showUnlockDialog(NoteModel detail) {
    Get.bottomSheet(
      UnlockVaultView(
        onUnlock: (pin) {
          if (pin == '1234') { // Mock PIN
            Get.back(); // Close bottom sheet
            _loadNoteData(detail);
          } else {
            HapticFeedback.heavyImpact();
            UIHelpers.showSnackBar('Error', 'Invalid PIN', isError: true);
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void addTextBlock() {
    blocks.add(ContentBlockModel(id: _uuid.v4(), type: 'text', text: ''));
  }
  void addChecklistBlock() {
    blocks.add(ContentBlockModel(
      id: _uuid.v4(), 
      type: 'checklist', 
      items: [ChecklistItemModel(id: _uuid.v4(), text: '', checked: false)]
    ));
  }

  Future<void> addImageBlock() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final blockId = _uuid.v4();
      blocks.add(ContentBlockModel(
        id: blockId,
        type: 'attachment',
        displayName: image.name,
        text: image.path,
      ));
      // If note exists, upload immediately
      if (note.value?.id != null) {
        await _repository.uploadAttachment(
          noteId: note.value!.id!,
          filePath: image.path,
          blockId: blockId,
        );
        initNote(note.value!.id!); // Refresh note to get real attachment data
      }
    }
  }

  Future<void> addVideoBlock() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final blockId = _uuid.v4();
      blocks.add(ContentBlockModel(
        id: blockId,
        type: 'attachment',
        displayName: video.name,
        text: video.path,
      ));
      // If note exists, upload immediately
      if (note.value?.id != null) {
        await _repository.uploadAttachment(
          noteId: note.value!.id!,
          filePath: video.path,
          blockId: blockId,
        );
        initNote(note.value!.id!); // Refresh note to get real attachment data
      }
    }
  }

  Future<void> addFileBlock() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = result.files.first;
      final blockId = _uuid.v4();
      blocks.add(ContentBlockModel(
        id: blockId,
        type: 'attachment',
        displayName: file.name,
        text: file.path,
      ));

      if (note.value?.id != null && file.path != null) {
        await _repository.uploadAttachment(
          noteId: note.value!.id!,
          filePath: file.path!,
          blockId: blockId,
        );
        initNote(note.value!.id!); // Refresh note
      }
    }
  }

  Future<void> deleteAttachment(int attachmentId) async {
    try {
      await _repository.deleteAttachment(attachmentId);
      if (note.value?.id != null) {
        initNote(note.value!.id!); // Refresh list
      }
      UIHelpers.showSnackBar('Success', 'Attachment deleted');
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to delete attachment', isError: true);
    }
  }

  void updateTextBlock(int index, String text) {
    final oldBlock = blocks[index];
    blocks[index] = ContentBlockModel(
      id: oldBlock.id,
      type: 'text',
      text: text,
    );
  }

  void toggleChecklistItem(int blockIndex, int itemIndex) {
    final block = blocks[blockIndex];
    if (block.items == null) return;
    final items = List<ChecklistItemModel>.from(block.items!);
    final oldItem = items[itemIndex];
    items[itemIndex] = ChecklistItemModel(
      id: oldItem.id,
      text: oldItem.text,
      checked: !oldItem.checked,
    );
    blocks[blockIndex] = ContentBlockModel(
      id: block.id,
      type: 'checklist',
      items: items,
    );
  }

  void updateChecklistItemText(int blockIndex, int itemIndex, String text) {
    final block = blocks[blockIndex];
    if (block.items == null) return;
    
    final items = List<ChecklistItemModel>.from(block.items!);
    final oldItem = items[itemIndex];
    items[itemIndex] = ChecklistItemModel(
      id: oldItem.id,
      text: text,
      checked: oldItem.checked,
    );

    blocks[blockIndex] = ContentBlockModel(
      id: block.id,
      type: 'checklist',
      items: items,
    );
  }

  Future<void> saveNote() async {
    if (titleController.text.isEmpty) return;
    isLoading.value = true;
    try {
      final noteId = note.value?.id ?? 0;
      final folderId = selectedFolderId.value;
      final savedId = await _repository.saveNote(noteId, folderId, titleController.text);
      final idToSave = note.value?.id ?? savedId ?? 0;
      if (idToSave != 0) {
        await _repository.saveContent(
          idToSave, 
          titleController.text, 
          blocks.map((e) => e.toJson()).toList()
        );
        // Refresh local note state
        if (note.value == null && savedId != null) {
          initNote(savedId);
        }
        // Refresh Note List if it exists
        if (Get.isRegistered<NoteListController>()) {
          Get.find<NoteListController>().fetchAllNotes();
        }
        // Refresh Home if it exists
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().fetchData();
        }
        // Refresh Folder if it exists
        if (Get.isRegistered<FolderController>()) {
          final folderController = Get.find<FolderController>();
          if (folderController.selectedFolder.value != null) {
            folderController.selectFolder(folderController.selectedFolder.value!, navigate: false);
          }
        }
        UIHelpers.showSnackBar('Success', 'Note saved');
        Get.back(); // iOS-style: close screen after saving
      }
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to save note: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> togglePin() async {
    if (note.value == null) return;
    final newState = !note.value!.isPinned;
    try {
      await _repository.updateNoteState(id: note.value!.id!, isPinned: newState);
      note.value = note.value!.copyWith(isPinned: newState);
      // Refresh Home if it exists
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchData();
      }
      UIHelpers.showSnackBar('Success', newState ? 'Note pinned' : 'Note unpinned');
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to update pin status', isError: true);
    }
  }

  Future<void> toggleLock() async {
    if (note.value == null) return;
    final newState = !note.value!.isLocked;
    try {
      await _repository.updateNoteState(id: note.value!.id!, isLocked: newState);
      note.value = note.value!.copyWith(isLocked: newState);
      
      // Refresh relevant controllers
      if (Get.isRegistered<NoteListController>()) {
        Get.find<NoteListController>().fetchAllNotes();
      }
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchData();
      }
      
      UIHelpers.showSnackBar('Success', newState ? 'Note locked' : 'Note unlocked');
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to update lock status', isError: true);
    }
  }

  Future<void> archiveNote() async {
    if (note.value == null) return;
    final newState = !note.value!.isArchived;
    try {
      await _repository.updateNoteState(id: note.value!.id!, isArchived: newState);
      note.value = note.value!.copyWith(isArchived: newState);
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchData();
      }
      UIHelpers.showSnackBar('Success', newState ? 'Note archived' : 'Note restored');
      Get.back(); // Return to list
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to update archive status', isError: true);
    }
  }

  Future<void> deleteNote() async {
    if (note.value == null) return;
    try {
      await _repository.deleteRestoreNote(note.value!.id!, true);
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchData();
      }
      UIHelpers.showSnackBar('Success', 'Note moved to trash');
      Get.back();
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to delete note', isError: true);
    }
  }

  void changeFolder(int folderId) {
    selectedFolderId.value = folderId;
  }

  void removeBlock(int index) {
    blocks.removeAt(index);
  }
}
