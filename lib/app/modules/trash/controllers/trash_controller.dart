import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/providers/folder_service.dart';
import '../../../data/providers/note_service.dart';
import '../../../widgets/ios_confirmation_dialog.dart';

class TrashController extends GetxController {
  final _noteService = Get.find<NoteService>();
  final _folderService = Get.find<FolderService>();

  final trashNotes = <NoteModel>[].obs;
  final trashFolders = <FolderModel>[].obs;
  final isLoading = true.obs;
  final isEditing = false.obs;
  final selectedNoteIds = <int>{}.obs;
  final selectedFolderIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTrashItems();
  }

  @override
  void onReady() {
    super.onReady();
    fetchTrashItems();
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

  Future<void> fetchTrashItems() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _noteService.getTrashNotes(),
        _folderService.getFolders(),
      ]);

      final List<NoteModel> notes = results[0] as List<NoteModel>;
      final folderRes = results[1] as FolderResponse;

      final List<FolderModel> folders = (folderRes.trash).map((e) {
        if (e is Map<String, dynamic>) {
          return FolderModel.fromJson(e);
        }
        return FolderModel(
          id: e is int ? e : 0,
          name: "Deleted Folder",
          iconName: "folder",
          colorValue: "0xFFFFCC00",
          sortOrder: 0,
        );
      }).toList();

      trashNotes.assignAll(notes);
      trashFolders.assignAll(folders);

      debugPrint(
        "TRASH: Found ${trashNotes.length} notes and ${trashFolders.length} folders.",
      );
    } catch (e) {
      Get.snackbar("Error", "Could not load trash items");
    } finally {
      isLoading.value = false;
    }
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
      for (final id in noteIds) {
        await _noteService.deleteRestoreNote(id, false);
      }
      for (final id in folderIds) {
        await _folderService.deleteRestoreFolder(id, false);
      }

      selectedNoteIds.clear();
      selectedFolderIds.clear();
      isEditing.value = false;
      await fetchTrashItems();
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
      for (final note in trashNotes) {
        await _noteService.deleteRestoreNote(note.id, false);
      }
      for (final folder in trashFolders) {
        await _folderService.deleteRestoreFolder(folder.id, false);
      }
      isEditing.value = false;
      await fetchTrashItems();
      Get.snackbar("Success", "All items recovered");
    } catch (e) {
      Get.snackbar("Error", "Failed to recover all items");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePermanently() async {
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

    Get.dialog(
      IOSConfirmationDialog(
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
            await fetchTrashItems();
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
      ),
    );
  }

  Future<void> deleteAll() async {
    Get.dialog(
      IOSConfirmationDialog(
        title: "All items in trash will be permanently removed.",
        confirmLabel: "Empty Trash",
        onConfirm: () async {
          isLoading.value = true;
          try {
            await _noteService.emptyTrash();
            for (final folder in trashFolders) {
              await _folderService.deleteFolderPermanently(folder.id);
            }
            isEditing.value = false;
            await fetchTrashItems();
            Get.snackbar("Success", "Trash emptied");
          } catch (e) {
            Get.snackbar("Error", "Failed to empty trash");
          } finally {
            isLoading.value = false;
          }
        },
      ),
    );
  }
}
