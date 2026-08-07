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
      
      final List<FolderModel> folders = (folderRes.trash as List)
          .map((e) {
            if (e is Map<String, dynamic>) {
              return FolderModel.fromJson(e);
            }
            return FolderModel(id: e as int, name: "Deleted Folder", iconName: "folder", colorValue: "0xFFFFCC00", sortOrder: 0);
          })
          .toList();

      trashNotes.assignAll(notes);
      trashFolders.assignAll(folders);
      
      debugPrint("TRASH: Found ${trashNotes.length} notes and ${trashFolders.length} folders.");
    } catch (e) {
      Get.snackbar("Error", "Could not load trash items");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recoverSelectedItems() async {
    isLoading.value = true;
    try {
      for (final id in selectedNoteIds) {
        await _noteService.deleteRestoreNote(id, false);
      }
      for (final id in selectedFolderIds) {
        await _folderService.deleteRestoreFolder(id, false);
      }
      
      selectedNoteIds.clear();
      selectedFolderIds.clear();
      isEditing.value = false;
      await fetchTrashItems();
      Get.snackbar("Success", "Items recovered", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Could not recover items");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePermanently() async {
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
          // Add logic to perform actual permanent deletion from API
          await fetchTrashItems();
          Get.snackbar("Info", "Items permanently deleted", snackPosition: SnackPosition.BOTTOM);
        },
      ),
    );
  }
}
