import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_dialogs.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/display_preferences.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/folder/domain/folder_default_name.dart';
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
  final CreateAudioNote _createAudioNote;

  FolderController({
    required GetFolders getFolders,
    required SaveFolder saveFolder,
    required DeleteRestoreFolder deleteRestoreFolder,
    required BuildFolderHierarchy buildHierarchy,
    required GetNotes getNotes,
    required CreateAudioNote createAudioNote,
  }) : _getFolders = getFolders,
       _saveFolder = saveFolder,
       _deleteRestoreFolder = deleteRestoreFolder,
       _buildHierarchy = buildHierarchy,
       _getNotes = getNotes,
       _createAudioNote = createAudioNote;

  final _prefs = DisplayPreferences();

  final folders = <Folder>[].obs;
  final trashFolders = <Folder>[].obs;
  final deletedCount = 0.obs;
  final allNotesCount = 0.obs;
  final archivedCount = 0.obs;
  final isLoading = true.obs;
  final isEditing = false.obs;
  late final isGroupedByDate = _prefs.folderGroupByDate.obs;

  // Guards against duplicate API calls from double taps
  final isDeleting = false.obs;
  final isSaving = false.obs;

  // Section expanded states
  final isICloudExpanded = true.obs;
  final isOnMyiPhoneExpanded = true.obs;
  final isSharedExpanded = true.obs;
  final isNotesSectionExpanded = true.obs;

  /// Folders whose subfolders are hidden — a folder with children starts
  /// expanded, same as the "On My iPhone" section, and collapses via its own
  /// disclosure arrow.
  final collapsedFolderIds = <int>{}.obs;

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

  bool isFolderExpanded(int folderId) => !collapsedFolderIds.contains(folderId);

  void toggleFolderExpanded(int folderId) {
    if (collapsedFolderIds.contains(folderId)) {
      collapsedFolderIds.remove(folderId);
    } else {
      collapsedFolderIds.add(folderId);
    }
  }

  void toggleDateGrouping() {
    isGroupedByDate.value = !isGroupedByDate.value;
    _prefs.setFolderGroupByDate(isGroupedByDate.value);
    sortFolders();
    AppSnackbar.info(
      'folder_sort_updated'.tr,
      (isGroupedByDate.value
              ? 'folder_sorted_by_date_message'
              : 'folder_sorted_manually_message')
          .tr,
    );
  }

  void sortFolders() {
    if (isGroupedByDate.value) {
      folders.sort((a, b) {
        final dateA = a.updatedAt ?? a.createdAt ?? DateTime(0);
        final dateB = b.updatedAt ?? b.createdAt ?? DateTime(0);
        final dateOrder = dateB.compareTo(dateA);
        if (dateOrder != 0) return dateOrder;
        final manualOrder = a.sortOrder.compareTo(b.sortOrder);
        return manualOrder != 0 ? manualOrder : a.name.compareTo(b.name);
      });
    } else {
      folders.sort((a, b) {
        final cmp = a.sortOrder.compareTo(b.sortOrder);
        return cmp != 0 ? cmp : a.name.compareTo(b.name);
      });
    }
  }

  /// The full parent/child tree, built once from every folder's real
  /// `parentId` — independent of which section a folder's name puts it in.
  List<Folder> get _fullHierarchy => _buildHierarchy(folders).orElse(const []);

  /// The sidebar's three sections, each nested into a tree.
  ///
  /// Section membership is decided by each *root* folder's name only. The
  /// tree is built from the complete flat list first, so a subfolder whose
  /// name doesn't repeat its ancestor's "icloud"/"shared" keyword (e.g. a
  /// folder named "Work" nested under "iCloud Family") still nests under its
  /// real parent instead of being filtered out and silently disappearing.
  List<Folder> get iCloudFolders => _fullHierarchy
      .where((f) => f.name.toLowerCase().contains('icloud'))
      .toList();

  List<Folder> get sharedFolders => _fullHierarchy
      .where((f) => f.name.toLowerCase().contains('shared'))
      .toList();

  List<Folder> get onMyiPhoneFolders => _fullHierarchy.where((f) {
    final name = f.name.toLowerCase();
    return !name.contains('icloud') && !name.contains('shared');
  }).toList();

  /// Builds a parent/child tree from any flat folder list — used by the
  /// Location picker, which walks every section rather than just one.
  List<Folder> buildHierarchy(List<Folder> flat) =>
      _buildHierarchy(flat).orElse(const []);

  /// IDs of [folderId] and everything nested beneath it, so the Location
  /// picker can stop a folder from becoming its own descendant.
  Set<int> subtreeIds(int folderId) {
    final ids = <int>{folderId};
    void collect(int parentId) {
      for (final f in folders.where((f) => f.parentId == parentId)) {
        if (ids.add(f.id)) collect(f.id);
      }
    }

    collect(folderId);
    return ids;
  }

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
          parentId: parentId,
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

  void createNewNote() => _openNewNote();

  Future<void> saveRecordedAudio({
    required String filePath,
    required String displayName,
  }) async {
    final folder = _defaultNoteFolder;
    if (folder == null) {
      AppSnackbar.info(
        'No folders yet',
        'Please create a folder before recording a voice note.',
      );
      return;
    }

    final result = await _createAudioNote(
      CreateAudioNoteParams(
        folderId: folder.id,
        title: 'note_editor_recording_fallback_name'.tr,
        filePath: filePath,
        displayName: displayName,
        blockId: 'audio_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    switch (result) {
      case Ok():
        await fetchFolders(refresh: true);
        AppSnackbar.success(
          'note_editor_recording_fallback_name'.tr,
          'note_editor_voice_note_saved'.tr,
        );
      case Err(:final failure):
        AppSnackbar.failure('note_editor_could_not_save_recording'.tr, failure);
    }
  }

  Folder? get _defaultNoteFolder {
    if (folders.isEmpty) return null;
    return folders.firstWhere(
      (f) => f.name.toLowerCase().contains('notes'),
      orElse: () => folders.first,
    );
  }

  void _openNewNote({bool autoRecord = false}) {
    if (folders.isEmpty) {
      AppSnackbar.info(
        'No folders yet',
        'Please create a folder first before writing a note.',
      );
      return;
    }

    final defaultFolder = _defaultNoteFolder!;

    NoteNavigation.toNewNote(defaultFolder.id, autoRecord: autoRecord)?.then((
      value,
    ) {
      if (value == true) fetchFolders(refresh: true);
    });
  }

  void onMoveFolder(Folder folder) {
    IOSActionMenu.show(
      context: Get.context!,
      type: IOSMenuType.bottomSheet,
      title: "Move '${folder.displayName}' to Section",
      actions: [
        IOSMenuAction(
          label: 'Pii Cloud',
          icon: CupertinoIcons.cloud,
          onTap: () => _updateFolderSection(folder, 'iCloud'),
        ),
        IOSMenuAction(
          label: 'On My Phone',
          icon: CupertinoIcons.device_phone_portrait,
          onTap: () => _updateFolderSection(folder, ''),
        ),
      ],
    );
  }

  /// The section keyword ('iCloud' / 'Shared' / '') already baked into
  /// [folder]'s name — the inverse of [stripSectionKeyword], so a rename can
  /// reapply it and not silently drop the folder out of its section.
  String sectionKeywordOf(Folder folder) =>
      FolderAppearance.sectionKeywordOf(folder.name);

  /// The display label for [sectionKeywordOf]'s return value.
  String sectionLabel(String keyword) => FolderAppearance.sectionLabel(keyword);

  /// Strips any section/status keyword out of [name], leaving just the part
  /// the user actually typed.
  String stripSectionKeyword(String name) =>
      FolderAppearance.stripSectionKeyword(name);

  /// The next default name shown when opening the create-folder screen.
  /// Include Recently Deleted so a new folder does not reuse a name that is
  /// still restorable, and strip storage-section prefixes before comparing.
  String nextNewFolderName() => nextDefaultFolderName([
    for (final folder in folders) stripSectionKeyword(folder.name),
    for (final folder in trashFolders) stripSectionKeyword(folder.name),
  ]);

  /// Sections are encoded in the folder name, since the API has no field for
  /// them — so moving a folder means rewriting its name prefix.
  Future<void> _updateFolderSection(Folder folder, String section) async {
    var newName = stripSectionKeyword(folder.name);
    if (section.isNotEmpty) newName = '$section $newName';

    isLoading.value = true;
    try {
      final success = await onSaveFolder(
        id: folder.id,
        parentId: folder.parentId,
        name: newName,
        iconName: folder.iconName,
        colorValue: folder.colorValue,
        sortOrder: folder.sortOrder,
      );
      if (success && section.isNotEmpty) {
        AppSnackbar.success('Moved', 'Moved to ${sectionLabel(section)}');
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

    if (!await AppDialogs.confirmDeleteFolder(folder.displayName)) return;

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
