import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/providers/folder_service.dart';
import '../../../data/providers/note_service.dart';
import '../../../routes/note_navigation.dart';
import '../../../widgets/ios_confirmation_dialog.dart';
import '../../../widgets/ios_action_menu.dart';
import '../widgets/folder_create_modal.dart';

class FolderController extends GetxController {
  final _folderService = Get.find<FolderService>();
  final _noteService = Get.find<NoteService>();

  final folders = <FolderModel>[].obs;
  final trashFolders = <FolderModel>[].obs;
  final deletedCount = 0.obs;
  final allNotesCount = 0.obs;
  final archivedCount = 0.obs;
  final isLoading = true.obs;
  final isEditing = false.obs;
  final isGroupedByDate = false.obs;
  
  // Guards to prevent duplicate API calls
  final isDeleting = false.obs;
  final isSaving = false.obs;

  // Section expanded states
  final isICloudExpanded = true.obs;
  final isOnMyiPhoneExpanded = true.obs;
  final isSharedExpanded = true.obs;
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
  void toggleNotesSection() =>
      isNotesSectionExpanded.value = !isNotesSectionExpanded.value;

  void toggleDateGrouping() {
    isGroupedByDate.value = !isGroupedByDate.value;
    sortFolders();
    Get.snackbar(
      "Grouping Updated",
      "Folders are now ${isGroupedByDate.value ? 'grouped' : 'sorted'} by date.",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void sortFolders() {
    if (isGroupedByDate.value) {
      folders.sort((a, b) {
        final dateA = a.updatedAt ?? DateTime(0);
        final dateB = b.updatedAt ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
    } else {
      folders.sort((a, b) {
        int cmp = a.sortOrder.compareTo(b.sortOrder);
        if (cmp != 0) return cmp;
        return a.name.compareTo(b.name);
      });
    }
  }

  List<FolderModel> get iCloudFolders => folders
      .where(
        (f) =>
            f.name.toLowerCase().contains("icloud"),
      )
      .toList();

  List<FolderModel> get sharedFolders => folders
      .where(
        (f) =>
            f.name.toLowerCase().contains("shared"),
      )
      .toList();

  List<FolderModel> get onMyiPhoneFolders => folders
      .where(
        (f) =>
            !f.name.toLowerCase().contains("icloud") &&
            !f.name.toLowerCase().contains("shared"),
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
      folders.assignAll(response.folders);
      trashFolders.assignAll(response.trash);
      sortFolders();
      deletedCount.value = response.trash.length;

      // Fetch all notes count
      final NoteResponse allNotes = await _noteService.getNotes(
        refresh: refresh,
      );
      allNotesCount.value = allNotes.notes.length;
      archivedCount.value = allNotes.archive.length;
    } catch (e) {
      Get.snackbar("Error", "Could not load data");
    } finally {
      isLoading.value = false;
    }
  }

  /// FEATURE: Save or rename a folder.
  /// Returns true on success so the caller (modal) can call Get.back().
  Future<bool> onSaveFolder({
    required int id,
    required String name,
    String? iconName,
    String? colorValue,
    int? sortOrder,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      Get.snackbar("Error", "Folder name cannot be empty", snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    // Note: caller (FolderCreateLogic) manages its own isSaving guard.
    // We only guard here when called directly (e.g. from move/section update).
    if (isSaving.value) return false;
    isSaving.value = true;

    try {
      if (kDebugMode) debugPrint("[FOLDER] ${id == 0 ? 'CREATE' : 'UPDATE'} FolderId=$id Name=$cleanName");

      final result = await _folderService.saveFolder(
        FolderModel(
          id: id,
          name: cleanName,
          iconName: iconName ?? "folder",
          colorValue: colorValue ?? "#FF69B4", // Default to app pink
          sortOrder: sortOrder ?? 0,
        ),
      );

      final int code = _toInt(result['code']) ?? 0;

      if (code == 200 || code == 201) {
        // Refresh folder list so folder view is up-to-date
        await fetchFolders(refresh: true);
        // Reset edit mode so folder view returns to normal state
        isEditing.value = false;

        Get.snackbar(
          "Success",
          id == 0 ? "Folder created successfully" : "Folder updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
        return true; // ← caller will call Get.back()
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
    } finally {
      isSaving.value = false;
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
    Get.dialog(
      IOSActionMenu(
        type: IOSMenuType.bottomSheet,
        title: "Move '${folder.name}' to Section",
        actions: [
          IOSMenuAction(
            label: "iCloud",
            icon: CupertinoIcons.cloud,
            onTap: () => _updateFolderSection(folder, "iCloud"),
          ),
          IOSMenuAction(
            label: "Shared",
            icon: CupertinoIcons.person_2,
            onTap: () => _updateFolderSection(folder, "Shared"),
          ),
          IOSMenuAction(
            label: "On My iPhone",
            icon: CupertinoIcons.device_phone_portrait,
            onTap: () => _updateFolderSection(folder, ""),
          ),
        ],
      ),
    );
  }

  Future<void> _updateFolderSection(FolderModel folder, String section) async {
    String newName = folder.name;
    // Remove existing keywords (case insensitive)
    newName = newName
        .replaceAll(RegExp(r'icloud', caseSensitive: false), '')
        .replaceAll(RegExp(r'shared', caseSensitive: false), '')
        .replaceAll(RegExp(r'pinned', caseSensitive: false), '')
        .replaceAll(RegExp(r'favorite', caseSensitive: false), '')
        .trim();

    if (section.isNotEmpty) {
      newName = "$section $newName";
    }

    isLoading.value = true;
    try {
      final success = await onSaveFolder(
        id: folder.id,
        name: newName,
        iconName: folder.iconName,
        colorValue: folder.colorValue,
        sortOrder: folder.sortOrder,
      );
      if (success) {
        Get.snackbar("Success", "Moved to $section", snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void onRenameFolder(FolderModel folder) {
    Get.to(
      () => FolderCreateModal(folder: folder, controller: this),
      fullscreenDialog: false,
      transition: Transition.cupertino,
    );
  }

  void onToggleGroupByDate(FolderModel folder) {
    toggleDateGrouping();
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

    if (isDeleting.value) return;

    Get.dialog(
      IOSConfirmationDialog(
        title: "Are you sure you want to delete '${folder.name}'? Its notes will be moved to Recently Deleted.",
        confirmLabel: "Delete Folder",
        onConfirm: () async {
          if (isDeleting.value) return;
          isDeleting.value = true;
          isLoading.value = true;
          try {
            await _folderService.deleteRestoreFolder(folder.id, true);
            await fetchFolders(refresh: true);
            Get.snackbar(
              "Success",
              "Folder moved to Recently Deleted",
              snackPosition: SnackPosition.BOTTOM,
            );
          } catch (e) {
            Get.snackbar(
              "Error",
              "Could not delete folder. Please try again.",
            );
          } finally {
            isDeleting.value = false;
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
