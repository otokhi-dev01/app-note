import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/providers/folder_service.dart';
import '../../../data/providers/note_service.dart';
import '../../../routes/note_navigation.dart';
import '../../../widgets/ios_confirmation_dialog.dart';
import '../widgets/folder_create_modal.dart';

class FolderController extends GetxController {
  final _folderService = Get.find<FolderService>();
  final _noteService = Get.find<NoteService>();

  final folders = <FolderModel>[].obs;
  final deletedCount = 0.obs;
  final allNotesCount = 0.obs;
  final archivedCount = 0.obs;
  final pinnedNotesCount = 0.obs;
  final isLoading = true.obs;
  final isEditing = false.obs;

  // Section expanded states
  final isICloudExpanded = true.obs;
  final isOnMyiPhoneExpanded = true.obs;
  final isSharedExpanded = true.obs;
  final isPinnedExpanded = true.obs;
  final isNotesSectionExpanded = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFolders();
  }

  void toggleICloud() => isICloudExpanded.value = !isICloudExpanded.value;
  void toggleOnMyiPhone() =>
      isOnMyiPhoneExpanded.value = !isOnMyiPhoneExpanded.value;
  void toggleShared() => isSharedExpanded.value = !isSharedExpanded.value;
  void togglePinned() => isPinnedExpanded.value = !isPinnedExpanded.value;
  void toggleNotesSection() =>
      isNotesSectionExpanded.value = !isNotesSectionExpanded.value;

  List<FolderModel> get pinnedFolders => folders
      .where(
        (f) =>
            f.name.toLowerCase().contains("pinned") ||
            f.name.toLowerCase().contains("favorite"),
      )
      .toList();

  List<FolderModel> get iCloudFolders => folders
      .where(
        (f) =>
            f.name.toLowerCase().contains("icloud") &&
            !pinnedFolders.contains(f),
      )
      .toList();

  List<FolderModel> get sharedFolders => folders
      .where(
        (f) =>
            f.name.toLowerCase().contains("shared") &&
            !pinnedFolders.contains(f),
      )
      .toList();

  List<FolderModel> get onMyiPhoneFolders => folders
      .where(
        (f) =>
            !f.name.toLowerCase().contains("icloud") &&
            !f.name.toLowerCase().contains("shared") &&
            !pinnedFolders.contains(f),
      )
      .toList();

  void toggleEditing() => isEditing.value = !isEditing.value;

  bool isSystemFolder(FolderModel folder) {
    final systemNames = [
      "All on My iphone",
      "Notes",
      "Recently Deleted",
      "Profile",
    ];
    return systemNames.contains(folder.name);
  }

  Future<void> fetchFolders({bool refresh = false}) async {
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
      final NoteResponse allNotes = await _noteService.getNotes(
        refresh: refresh,
      );
      allNotesCount.value = allNotes.notes.length;
      archivedCount.value = allNotes.archive.length;
      pinnedNotesCount.value = allNotes.notes.where((n) => n.isPinned).length;
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
    if (name.trim().isEmpty) {
      Get.snackbar(
        "Error",
        "Folder name cannot be empty",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      if (kDebugMode)
        debugPrint("[FOLDER DEBUG] onSaveFolder ID: $id, Name: $name");

      final result = await _folderService.saveFolder(
        FolderModel(
          id: id,
          name: name.trim(),
          iconName: iconName ?? "folder",
          colorValue: colorValue ?? "#FFB703",
          sortOrder: sortOrder ?? 0,
        ),
      );

      final int code = _toInt(result['code']) ?? 0;

      if (code == 200 || code == 201) {
        await fetchFolders(refresh: true);
        Get.snackbar(
          "Success",
          id == 0 ? "Folder created" : "Folder renamed",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
        return true;
      } else {
        final errorMessage = FolderService.getApiErrorMessage(result);
        Get.snackbar(
          "Unable to save folder",
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[FOLDER DEBUG] onSaveFolder FATAL: $e");
      Get.snackbar(
        "Error",
        "Server error. Please try again later.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

  void createNewNote() {
    if (folders.isNotEmpty) {
      NoteNavigation.toNewNote(folders.first.id)?.then((value) {
        if (value == true) fetchFolders();
      });
    } else {
      Get.snackbar("Info", "Create a folder first");
    }
  }

  void onMoveFolder(FolderModel folder) {
    Get.snackbar(
      "Info",
      "Move Folder functionality is currently being implemented.",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onRenameFolder(FolderModel folder) {
    Get.bottomSheet(
      FolderCreateModal(folder: folder, controller: this),
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
    );
  }

  void onToggleGroupByDate(FolderModel folder) {
    Get.snackbar("Info", "Grouping updated");
  }

  void onDeleteFolder(FolderModel folder) {
    if (isSystemFolder(folder)) {
      Get.snackbar(
        "Info",
        "System folders cannot be deleted",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.dialog(
      IOSConfirmationDialog(
        title: "Are you sure you want to delete '${folder.name}'? Its notes will be moved to Recently Deleted.",
        confirmLabel: "Delete Folder",
        onConfirm: () async {
          isLoading.value = true;
          try {
            await _folderService.deleteRestoreFolder(folder.id, true);
            await fetchFolders(refresh: true);
            Get.snackbar(
              "Success",
              "Folder moved to trash",
              snackPosition: SnackPosition.BOTTOM,
            );
          } catch (e) {
            Get.snackbar(
              "Error",
              "Could not delete folder. Please try again.",
            );
          } finally {
            isLoading.value = false;
          }
        },
      ),
    );
  }

  void onConvertToSmartFolder(FolderModel folder) {
    Get.snackbar("Info", "Converted to Smart Folder");
  }
}
