import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/note_model.dart';
import '../../data/services/folder_service.dart';
import '../../data/services/note_service.dart';
import '../../routes/app_pages.dart';
import '../../routes/note_navigation.dart';
import 'widgets/folder_create_modal.dart';

class FolderController extends GetxController {
  final _folderService = Get.find<FolderService>();
  final _noteService = Get.find<NoteService>();

  final folders = <FolderModel>[].obs;
  final deletedCount = 0.obs;
  final allNotesCount = 0.obs;
  final archivedCount = 0.obs;
  final isLoading = true.obs;
  final isEditing = false.obs;
  
  // Section expanded states
  final isICloudExpanded = true.obs;
  final isOnMyiPhoneExpanded = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFolders();
  }

  void toggleICloud() => isICloudExpanded.value = !isICloudExpanded.value;
  void toggleOnMyiPhone() => isOnMyiPhoneExpanded.value = !isOnMyiPhoneExpanded.value;

  List<FolderModel> get iCloudFolders => folders.where((f) => 
    f.name.toLowerCase().contains("icloud")
  ).toList();
  
  List<FolderModel> get onMyiPhoneFolders => folders.where((f) => 
    !f.name.toLowerCase().contains("icloud")
  ).toList();

  void toggleEditing() => isEditing.value = !isEditing.value;

  bool isSystemFolder(FolderModel folder) {
    final systemNames = ["All on My iPhone", "Notes", "Recently Deleted", "Profile"];
    return systemNames.contains(folder.name);
  }

  Future<void> fetchFolders() async {
    isLoading.value = true;
    try {
      final response = await _folderService.getFolders();
      // Sort by sortOrder then name
      response.folders.sort((a, b) {
        int cmp = a.sortOrder.compareTo(b.sortOrder);
        if (cmp != 0) return cmp;
        return a.name.compareTo(b.name);
      });
      folders.assignAll(response.folders);
      deletedCount.value = response.trash.length;
      
      // Fetch all notes count
      final NoteResponse allNotes = await _noteService.getNotes();
      allNotesCount.value = allNotes.notes.length;
      archivedCount.value = allNotes.archive.length;
    } catch (e) {
      Get.snackbar("Error", "Could not load data");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> onSaveFolder({
    required int id,
    required String name,
    String? iconName,
    String? colorValue,
    int? sortOrder,
  }) async {
    try {
      final result = await _folderService.saveFolder(FolderModel(
        id: id,
        name: name,
        iconName: iconName ?? "folder",
        colorValue: colorValue ?? "#FFB703",
        sortOrder: sortOrder ?? 0,
      ));
      
      if (result['code'] == 200) {
        fetchFolders();
        return true;
      } else {
        Get.snackbar("Error", result['message'] ?? "Failed to save folder");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred");
      return false;
    }
  }

  void createNewNote() {
    if (folders.isNotEmpty) {
      NoteNavigation.toNewNote(folders.first.id)
          ?.then((value) {
            if (value == true) fetchFolders();
          });
    } else {
      Get.snackbar("Info", "Create a folder first");
    }
  }

  void onMoveFolder(FolderModel folder) {
    Get.snackbar("Info", "Move functionality coming soon");
  }

  void onRenameFolder(FolderModel folder) {
    Get.bottomSheet(
      FolderCreateModal(folder: folder, controller: this),
      isScrollControlled: true,
    );
  }

  void onToggleGroupByDate(FolderModel folder) {
    Get.snackbar("Info", "Grouping updated");
  }

  void onDeleteFolder(FolderModel folder) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Folder?"),
        content: Text("Are you sure you want to delete '${folder.name}'? All notes in this folder will be moved to Recently Deleted."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _folderService.deleteRestoreFolder(folder.id, true);
              Get.back();
              fetchFolders();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void onConvertToSmartFolder(FolderModel folder) {
    Get.snackbar("Info", "Converted to Smart Folder");
  }
}
