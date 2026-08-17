import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_appearance.dart';
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

  List<FolderModel> _buildHierarchy(List<FolderModel> flatList) {
    // 1. Create a map for quick lookup
    final Map<int, List<FolderModel>> childrenMap = {};
    final List<FolderModel> roots = [];

    for (var folder in flatList) {
      if (folder.parentId == null || folder.parentId == 0) {
        roots.add(folder);
      } else {
        childrenMap.putIfAbsent(folder.parentId!, () => []).add(folder);
      }
    }

    // 2. Recursively attach children
    List<FolderModel> attachChildren(List<FolderModel> currentLevel) {
      return currentLevel.map((folder) {
        final children = childrenMap[folder.id] ?? [];
        return FolderModel(
          id: folder.id,
          parentId: folder.parentId,
          name: folder.name,
          iconName: folder.iconName,
          colorValue: folder.colorValue,
          sortOrder: folder.sortOrder,
          noteCount: folder.noteCount,
          createdAt: folder.createdAt,
          updatedAt: folder.updatedAt,
          deletedAt: folder.deletedAt,
          subFolders: attachChildren(children),
        );
      }).toList();
    }

    return attachChildren(roots);
  }

  List<FolderModel> get iCloudFolders => _buildHierarchy(folders
      .where(
        (f) => f.name.toLowerCase().contains("icloud"),
      )
      .toList());

  List<FolderModel> get sharedFolders => _buildHierarchy(folders
      .where(
        (f) => f.name.toLowerCase().contains("shared"),
      )
      .toList());

  List<FolderModel> get onMyiPhoneFolders => _buildHierarchy(folders
      .where(
        (f) =>
            !f.name.toLowerCase().contains("icloud") &&
            !f.name.toLowerCase().contains("shared"),
      )
      .toList());

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
      final allNotes = await _noteService.getNotes(refresh: refresh);

      // Group notes by folderId for accurate client-side counts
      final Map<int, int> actualCounts = {};
      for (var note in allNotes.notes) {
        actualCounts[note.folderId] = (actualCounts[note.folderId] ?? 0) + 1;
      }

      // Update folders with actual counts to fix server-side inconsistencies
      final updatedFolders = response.folders.map((f) {
        return FolderModel(
          id: f.id,
          parentId: f.parentId,
          name: f.name,
          iconName: f.iconName,
          colorValue: f.colorValue,
          sortOrder: f.sortOrder,
          noteCount: actualCounts[f.id] ?? 0, // USE ACCURATE COUNT
          createdAt: f.createdAt,
          updatedAt: f.updatedAt,
          deletedAt: f.deletedAt,
          subFolders: f.subFolders,
        );
      }).toList();

      folders.assignAll(updatedFolders);
      trashFolders.assignAll(response.trash);
      sortFolders();
      
      // FEATURE: Sum both deleted folders and deleted notes for the "Recently Deleted" tile
      deletedCount.value = response.trash.length + allNotes.trash.length;

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
    int? parentId,
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

    if (isSaving.value) return false;
    isSaving.value = true;

    try {
      if (kDebugMode) debugPrint("[FOLDER] ${id == 0 ? 'CREATE' : 'UPDATE'} FolderId=$id ParentId=$parentId Name=$cleanName");

      final result = await _folderService.saveFolder(
        FolderModel(
          id: id,
          parentId: parentId,
          name: cleanName,
          // Normalized so legacy folders with a blank appearance get a real
          // icon/color instead of persisting an empty string back to the API.
          iconName: FolderAppearance.normalizeIcon(iconName),
          colorValue: FolderAppearance.normalizeColor(colorValue),
          sortOrder: sortOrder ?? 0,
        ),
      );

      final int code = _toInt(result['code']) ?? 0;

      if (code == 200 || code == 201) {
        await fetchFolders(refresh: true);
        
        // Root Cause Fix: "Clear screen back" - Exit edit mode and selection UI
        isEditing.value = false;
        
        Get.snackbar(
          "Success",
          id == 0 ? "Folder created successfully" : "Folder updated successfully",
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
    } finally {
      isSaving.value = false;
    }
  }

  int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

  /// FEATURE: Logic to Create a New Note
  void createNewNote() {
    if (folders.isEmpty) {
      Get.snackbar("Info", "Please create a folder first before writing a note.");
      return;
    }

    final defaultFolder = folders.firstWhere(
      (f) => f.name.toLowerCase().contains("notes"),
      orElse: () => folders.first,
    );

    NoteNavigation.toNewNote(defaultFolder.id)?.then((value) {
      if (value == true) {
        fetchFolders(refresh: true);
      }
    });
  }

  void onMoveFolder(FolderModel folder) {
    IOSActionMenu.show(
      context: Get.context!,
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
    );
  }

  Future<void> _updateFolderSection(FolderModel folder, String section) async {
    String newName = folder.name;
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
      fullscreenDialog: true,
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

    IOSConfirmationDialog.show(
      title:
          "Are you sure you want to delete '${folder.name}'? Its notes will be moved to Recently Deleted.",
      confirmLabel: "Delete Folder",
      onConfirm: () async {
        Get.back();
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
    );
  }

  void onConvertToSmartFolder(FolderModel folder) {
    Get.snackbar("Info", "Converted to Smart Folder");
  }
}
