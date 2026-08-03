import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/models/note_model.dart';
import '../../data/models/folder_model.dart';
import '../../data/services/note_service.dart';
import '../../data/services/folder_service.dart';
import '../../widgets/ios_confirmation_dialog.dart';

class RecentlyDeletedController extends GetxController {
  final _noteService = Get.find<NoteService>();
  final _folderService = Get.find<FolderService>();
  
  final deletedNotes = <NoteModel>[].obs;
  final deletedFolders = <FolderModel>[].obs;
  final isLoading = true.obs;
  final isEditing = false.obs;
  final selectedNoteIds = <int>{}.obs;
  final selectedFolderIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDeletedItems();
  }

  @override
  void onReady() {
    super.onReady();
    fetchDeletedItems(); // Re-fetch when user returns to screen
  }

  void toggleEditing() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      selectedNoteIds.clear();
      selectedFolderIds.clear();
    }
  }

  void toggleSelectNote(int id) {
    if (selectedNoteIds.contains(id)) {
      selectedNoteIds.remove(id);
    } else {
      selectedNoteIds.add(id);
    }
  }

  void toggleSelectFolder(int id) {
    if (selectedFolderIds.contains(id)) {
      selectedFolderIds.remove(id);
    } else {
      selectedFolderIds.add(id);
    }
  }

  Future<void> fetchDeletedItems() async {
    isLoading.value = true;
    try {
      // 1. Fetch Trash Notes
      final noteResponse = await _noteService.getTrashNotes();
      
      // 2. Fetch All Folders (which includes the trash list)
      final folderRes = await _folderService.getFolders();
      
      // Clear current lists
      deletedNotes.clear();
      deletedFolders.clear();

      // Map Note Models
      deletedNotes.assignAll(noteResponse);

      // Map Folder Models from the trash list
      final List<FolderModel> folders = (folderRes.trash as List).map((e) {
        if (e is Map<String, dynamic>) {
          return FolderModel.fromJson(e);
        }
        return FolderModel(id: 0, name: "Unknown Folder", iconName: "folder", colorValue: "0xFFFFCC00", sortOrder: 0);
      }).toList();
      
      deletedFolders.assignAll(folders);

      debugPrint("SUCCESS: Fetched ${deletedNotes.length} notes and ${deletedFolders.length} folders in trash.");
    } catch (e, stack) {
      debugPrint("ERROR in fetchDeletedItems: $e");
      debugPrint(stack.toString());
      Get.snackbar("Error", "Could not load deleted items");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recoverItem({int? noteId, int? folderId}) async {
    try {
      if (noteId != null) {
        await _noteService.deleteRestoreNote(noteId, false);
      } else if (folderId != null) {
        await _folderService.deleteRestoreFolder(folderId, false);
      }
      await fetchDeletedItems();
      Get.snackbar("Success", "Item recovered", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Could not recover item");
    }
  }

  Future<void> deleteItemPermanently({int? noteId, int? folderId, String? name}) async {
    String message = noteId != null 
        ? "This note will be deleted. This action cannot be undone."
        : "This folder and its notes will be deleted. This action cannot be undone.";
    String label = noteId != null ? "Delete Note" : "Delete Folder";

    Get.dialog(
      IOSConfirmationDialog(
        title: message,
        confirmLabel: label,
        onConfirm: () async {
          // Actual permanent delete logic (API call)
          // For now, refreshing the list
          await fetchDeletedItems();
          Get.snackbar("Info", "Item permanently deleted", snackPosition: SnackPosition.BOTTOM);
        },
      ),
    );
  }

  Future<void> recoverSelectedItems() async {
    try {
      // Recover notes
      for (final id in selectedNoteIds) {
        await _noteService.deleteRestoreNote(id, false);
      }
      // Recover folders
      for (final id in selectedFolderIds) {
        await _folderService.deleteRestoreFolder(id, false);
      }
      
      selectedNoteIds.clear();
      selectedFolderIds.clear();
      isEditing.value = false;
      await fetchDeletedItems();
      Get.snackbar("Success", "Items recovered", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Could not recover items");
    }
  }

  Future<void> deletePermanentlySelectedItems() async {
    final noteCount = selectedNoteIds.length;
    final folderCount = selectedFolderIds.length;
    
    if (noteCount == 0 && folderCount == 0) return;

    String message = folderCount > 0 
        ? "This folder and its notes will be deleted. This action cannot be undone."
        : "This note will be deleted. This action cannot be undone.";
    String label = folderCount > 0 ? "Delete Folder" : "Delete Note";

    Get.dialog(
      IOSConfirmationDialog(
        title: message,
        confirmLabel: label,
        onConfirm: () async {
          // Actual permanent delete logic (API call)
          await fetchDeletedItems();
          Get.snackbar("Info", "Items permanently deleted", snackPosition: SnackPosition.BOTTOM);
        },
      ),
    );
  }
}
