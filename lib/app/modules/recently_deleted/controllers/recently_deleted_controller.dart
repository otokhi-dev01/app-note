import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/providers/folder_service.dart';
import '../../../data/providers/note_service.dart';
import '../../../widgets/ios_confirmation_dialog.dart';

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
      // Root Cause Fix: folderRes.trash is already List<FolderModel>
      deletedFolders.assignAll(folderRes.trash);

      debugPrint(
        "SUCCESS: Fetched ${deletedNotes.length} notes and ${deletedFolders.length} folders in trash.",
      );
    } catch (e, stack) {
      debugPrint("ERROR in fetchDeletedItems: $e");
      debugPrint(stack.toString());
      Get.snackbar("Error", "Could not load deleted items");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recoverItem({int? noteId, int? folderId}) async {
    isLoading.value = true;
    try {
      if (noteId != null) {
        await _noteService.deleteRestoreNote(noteId, false);
      } else if (folderId != null) {
        await _folderService.deleteRestoreFolder(folderId, false);
      }
      await fetchDeletedItems();
      Get.snackbar(
        "Success",
        "Item recovered",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Error", "Could not recover item");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteItemPermanently({
    int? noteId,
    int? folderId,
    String? name,
  }) async {
    String message = noteId != null
        ? "This note will be deleted. This action cannot be undone."
        : "This folder and its notes will be deleted. This action cannot be undone.";
    String label = noteId != null ? "Delete Note" : "Delete Folder";

    IOSConfirmationDialog.show(
      title: message,
      confirmLabel: label,
      onConfirm: () async {
        try {
          if (noteId != null) {
            await _noteService.deleteNotePermanently(noteId);
            // Optimistic UI: remove from local list instantly
            deletedNotes.removeWhere((n) => n.id == noteId);
          } else if (folderId != null) {
            await _folderService.deleteFolderPermanently(folderId);
            // Optimistic UI: remove from local list instantly
            deletedFolders.removeWhere((f) => f.id == folderId);
          }
          await fetchDeletedItems();
          Get.snackbar(
            "Success",
            "Item permanently deleted",
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (e) {
          Get.snackbar("Error", "Could not delete item permanently");
        }
      },
    );
  }

  Future<void> recoverSelectedItems() async {
    final noteIds = selectedNoteIds.toList();
    final folderIds = selectedFolderIds.toList();

    // If nothing selected but in edit mode, recover all
    if (noteIds.isEmpty && folderIds.isEmpty && isEditing.value) {
      await recoverAll();
      return;
    }

    isLoading.value = true;
    try {
      // Recover notes
      for (final id in noteIds) {
        await _noteService.deleteRestoreNote(id, false);
      }
      // Recover folders
      for (final id in folderIds) {
        await _folderService.deleteRestoreFolder(id, false);
      }

      selectedNoteIds.clear();
      selectedFolderIds.clear();
      isEditing.value = false;
      await fetchDeletedItems();
      Get.snackbar(
        "Success",
        "Items recovered",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Error", "Could not recover items");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recoverAll() async {
    isLoading.value = true;
    try {
      for (final note in deletedNotes) {
        await _noteService.deleteRestoreNote(note.id, false);
      }
      for (final folder in deletedFolders) {
        await _folderService.deleteRestoreFolder(folder.id, false);
      }
      isEditing.value = false;
      await fetchDeletedItems();
      Get.snackbar("Success", "All items recovered");
    } catch (e) {
      Get.snackbar("Error", "Failed to recover all items");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePermanentlySelectedItems() async {
    final noteCount = selectedNoteIds.length;
    final folderCount = selectedFolderIds.length;

    if (noteCount == 0 && folderCount == 0) {
      if (isEditing.value) await deleteAll();
      return;
    }

    String message = folderCount > 0
        ? "These folders and their notes will be deleted. This action cannot be undone."
        : "These notes will be deleted. This action cannot be undone.";
    String label = "Delete";

    IOSConfirmationDialog.show(
      title: message,
      confirmLabel: label,
      onConfirm: () async {
        isLoading.value = true;
        try {
          for (final id in selectedNoteIds) {
            await _noteService.deleteNotePermanently(id);
          }
          for (final id in selectedFolderIds) {
            await _folderService.deleteFolderPermanently(id);
          }
          selectedNoteIds.clear();
          selectedFolderIds.clear();
          isEditing.value = false;
          await fetchDeletedItems();
          Get.snackbar(
            "Success",
            "Items permanently deleted",
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (e) {
          Get.snackbar("Error", "Could not delete items permanently");
        } finally {
          isLoading.value = false;
        }
      },
    );
  }

  Future<void> deleteAll() async {
    IOSConfirmationDialog.show(
      title:
          "All notes and folders in Recently Deleted will be permanently removed.",
      confirmLabel: "Empty Trash",
      onConfirm: () async {
        isLoading.value = true;
        try {
          await _noteService.emptyTrash();
          // Also need to handle folders if emptyTrash doesn't cover them
          for (final folder in deletedFolders) {
            await _folderService.deleteFolderPermanently(folder.id);
          }
          isEditing.value = false;
          await fetchDeletedItems();
          Get.snackbar("Success", "Trash emptied");
        } catch (e) {
          Get.snackbar("Error", "Failed to empty trash");
        } finally {
          isLoading.value = false;
        }
      },
    );
  }
}
