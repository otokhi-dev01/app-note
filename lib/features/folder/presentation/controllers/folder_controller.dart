import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_dialogs.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/folder/presentation/widgets/folder_create_modal.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';
import 'package:Note/routes/note_navigation.dart';
import 'package:Note/shared/widgets/ios_action_menu.dart';

class FolderController extends GetxController {
  final GetFolders _getFolders;
  final SaveFolder _saveFolder;
  final DeleteRestoreFolder _deleteRestoreFolder;
  final BuildFolderHierarchy _buildHierarchy;
  final GetNotes _getNotes;

  FolderController({
    required GetFolders getFolders,
    required SaveFolder saveFolder,
    required DeleteRestoreFolder deleteRestoreFolder,
    required BuildFolderHierarchy buildHierarchy,
    required GetNotes getNotes,
  }) : _getFolders = getFolders,
       _saveFolder = saveFolder,
       _deleteRestoreFolder = deleteRestoreFolder,
       _buildHierarchy = buildHierarchy,
       _getNotes = getNotes;

  final folders = <Folder>[].obs;
  final trashFolders = <Folder>[].obs;
  final deletedCount = 0.obs;
  final allNotesCount = 0.obs;
  final archivedCount = 0.obs;
  final isLoading = true.obs;
  final isEditing = false.obs;
  final isGroupedByDate = false.obs;

  // Guards against duplicate API calls from double taps
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
    AppSnackbar.info(
      'Grouping Updated',
      'Folders are now ${isGroupedByDate.value ? 'grouped' : 'sorted'} by date.',
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
        final cmp = a.sortOrder.compareTo(b.sortOrder);
        return cmp != 0 ? cmp : a.name.compareTo(b.name);
      });
    }
  }

  /// The sidebar's three sections, each nested into a tree.
  List<Folder> get iCloudFolders =>
      _hierarchyOf((f) => f.name.toLowerCase().contains('icloud'));

  List<Folder> get sharedFolders =>
      _hierarchyOf((f) => f.name.toLowerCase().contains('shared'));

  List<Folder> get onMyiPhoneFolders => _hierarchyOf((f) {
    final name = f.name.toLowerCase();
    return !name.contains('icloud') && !name.contains('shared');
  });

  List<Folder> _hierarchyOf(bool Function(Folder) where) =>
      _buildHierarchy(folders.where(where).toList()).orElse(const []);

  void toggleEditing() => isEditing.value = !isEditing.value;

  bool isSystemFolder(Folder folder) => const [
    'All on My iphone',
    'Notes',
    'Recently Deleted',
    'Profile',
  ].contains(folder.name);

  Future<void> fetchFolders({bool refresh = false}) async {
    isLoading.value = true;
    try {
      final folderResult = await _getFolders(const NoParams());
      final noteResult = await _getNotes(const GetNotesParams());

      if (folderResult case Err(:final failure)) {
        AppSnackbar.failure('Folders', failure);
        return;
      }
      if (noteResult case Err(:final failure)) {
        AppSnackbar.failure('Notes', failure);
        return;
      }

      final folderBundle = folderResult.valueOrNull!;
      final noteBundle = noteResult.valueOrNull!;

      // The server's per-folder note counts drift, so derive them from the
      // notes we just fetched instead of trusting the folder payload.
      final counts = <int, int>{};
      for (final note in noteBundle.notes) {
        counts[note.folderId] = (counts[note.folderId] ?? 0) + 1;
      }

      folders.assignAll([
        for (final f in folderBundle.folders)
          Folder(
            id: f.id,
            parentId: f.parentId,
            name: f.name,
            iconName: f.iconName,
            colorValue: f.colorValue,
            sortOrder: f.sortOrder,
            noteCount: counts[f.id] ?? 0,
            createdAt: f.createdAt,
            updatedAt: f.updatedAt,
            deletedAt: f.deletedAt,
            subFolders: f.subFolders,
          ),
      ]);
      trashFolders.assignAll(folderBundle.trash);
      sortFolders();

      // "Recently Deleted" counts both trashed folders and trashed notes.
      deletedCount.value = folderBundle.trash.length + noteBundle.trash.length;
      allNotesCount.value = noteBundle.notes.length;
      archivedCount.value = noteBundle.archive.length;
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
    if (isSaving.value) return false;
    isSaving.value = true;

    try {
      final result = await _saveFolder(
        SaveFolderParams(
          id: id,
          name: name,
          // Normalized so legacy folders with a blank appearance get a real
          // icon/color instead of persisting an empty string back to the API.
          iconName: FolderAppearance.normalizeIcon(iconName),
          colorValue: FolderAppearance.normalizeColor(colorValue),
          sortOrder: sortOrder ?? 0,
        ),
      );

      switch (result) {
        case Ok():
          await fetchFolders(refresh: true);
          isEditing.value = false;
          AppSnackbar.success(
            'Success',
            id == 0
                ? 'Folder created successfully'
                : 'Folder updated successfully',
          );
          return true;
        case Err(:final failure):
          AppSnackbar.failure('Unable to save folder', failure);
          return false;
      }
    } finally {
      isSaving.value = false;
    }
  }

  void createNewNote() {
    if (folders.isEmpty) {
      AppSnackbar.info(
        'No folders yet',
        'Please create a folder first before writing a note.',
      );
      return;
    }

    final defaultFolder = folders.firstWhere(
      (f) => f.name.toLowerCase().contains('notes'),
      orElse: () => folders.first,
    );

    NoteNavigation.toNewNote(defaultFolder.id)?.then((value) {
      if (value == true) fetchFolders(refresh: true);
    });
  }

  void onMoveFolder(Folder folder) {
    IOSActionMenu.show(
      context: Get.context!,
      type: IOSMenuType.bottomSheet,
      title: "Move '${folder.name}' to Section",
      actions: [
        IOSMenuAction(
          label: 'iCloud',
          icon: CupertinoIcons.cloud,
          onTap: () => _updateFolderSection(folder, 'iCloud'),
        ),
        IOSMenuAction(
          label: 'Shared',
          icon: CupertinoIcons.person_2,
          onTap: () => _updateFolderSection(folder, 'Shared'),
        ),
        IOSMenuAction(
          label: 'On My iPhone',
          icon: CupertinoIcons.device_phone_portrait,
          onTap: () => _updateFolderSection(folder, ''),
        ),
      ],
    );
  }

  /// Sections are encoded in the folder name, since the API has no field for
  /// them — so moving a folder means rewriting its name prefix.
  Future<void> _updateFolderSection(Folder folder, String section) async {
    var newName = folder.name
        .replaceAll(RegExp(r'icloud', caseSensitive: false), '')
        .replaceAll(RegExp(r'shared', caseSensitive: false), '')
        .replaceAll(RegExp(r'pinned', caseSensitive: false), '')
        .replaceAll(RegExp(r'favorite', caseSensitive: false), '')
        .trim();

    if (section.isNotEmpty) newName = '$section $newName';

    isLoading.value = true;
    try {
      final success = await onSaveFolder(
        id: folder.id,
        name: newName,
        iconName: folder.iconName,
        colorValue: folder.colorValue,
        sortOrder: folder.sortOrder,
      );
      if (success && section.isNotEmpty) {
        AppSnackbar.success('Moved', 'Moved to $section');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void onRenameFolder(Folder folder) {
    Get.to(
      () => FolderCreateModal(folder: folder, controller: this),
      fullscreenDialog: true,
      transition: Transition.cupertino,
    );
  }

  void onToggleGroupByDate(Folder folder) => toggleDateGrouping();

  Future<void> onDeleteFolder(Folder folder) async {
    if (isSystemFolder(folder)) {
      AppSnackbar.info('Not allowed', 'System folders cannot be deleted.');
      return;
    }
    if (isDeleting.value) return;

    if (!await AppDialogs.confirmDeleteFolder(folder.name)) return;

    isDeleting.value = true;
    isLoading.value = true;
    try {
      final result = await _deleteRestoreFolder(
        DeleteRestoreFolderParams(folderId: folder.id, isDelete: true),
      );
      switch (result) {
        case Ok():
          await fetchFolders(refresh: true);
          AppSnackbar.success('Deleted', 'Folder moved to Recently Deleted');
        case Err(:final failure):
          AppSnackbar.failure('Could not delete folder', failure);
      }
    } finally {
      isDeleting.value = false;
      isLoading.value = false;
    }
  }

  void onConvertToSmartFolder(Folder folder) {
    AppSnackbar.info('Smart Folder', 'Converted to Smart Folder');
  }
}
