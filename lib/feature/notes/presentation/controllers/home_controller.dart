import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/api_config.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../folders/domain/repositories/folder_repository.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/repositories/note_state_field.dart';

class HomeController extends GetxController {
  final FolderRepository folderRepository;
  final NoteRepository noteRepository;
  final AuthRepository authRepository;

  HomeController({
    required this.folderRepository,
    required this.noteRepository,
    required this.authRepository,
  });

  // ===========================================================================
  // DATA
  // ===========================================================================

  final RxList<FolderEntity> folders = <FolderEntity>[].obs;

  final RxList<FolderEntity> deletedFolders = <FolderEntity>[].obs;

  final RxList<NoteEntity> notes = <NoteEntity>[].obs;

  final Rxn<AuthSession> authSession = Rxn<AuthSession>();

  /*
   * A successful state POST can be followed by a stale note-list response.
   * Keep the confirmed state until the read API returns the same values.
   */
  final Map<int, NoteEntity> _pendingNoteStates = <int, NoteEntity>{};

  final RxSet<int> noteIdsBeingUpdated = <int>{}.obs;

  /*
   * A successful delete/restore POST can be followed by a stale GET response.
   * Keep the confirmed local operation until the read API acknowledges it.
   */
  final Map<int, FolderEntity> _pendingDeletedFolders = <int, FolderEntity>{};

  final Map<int, FolderEntity> _pendingRestoredFolders = <int, FolderEntity>{};

  int _folderLoadGeneration = 0;
  int _noteLoadGeneration = 0;

  /// Null means that all notes are selected.
  final RxnInt selectedFolderId = RxnInt();

  // ===========================================================================
  // LOADING
  // ===========================================================================

  final RxBool isFoldersLoading = false.obs;
  final RxBool isNotesLoading = false.obs;

  // ===========================================================================
  // ERRORS
  // ===========================================================================

  final RxString folderErrorMessage = ''.obs;
  final RxString noteErrorMessage = ''.obs;

  // ===========================================================================
  // COMPUTED PROPERTIES
  // ===========================================================================

  bool get isInitialLoading {
    return folders.isEmpty &&
        notes.isEmpty &&
        (isFoldersLoading.value || isNotesLoading.value);
  }

  bool get hasFolderError {
    return folderErrorMessage.value.trim().isNotEmpty;
  }

  bool get hasNoteError {
    return noteErrorMessage.value.trim().isNotEmpty;
  }

  bool get hasFolders {
    return folders.isNotEmpty;
  }

  bool get hasDeletedFolders {
    return deletedFolders.isNotEmpty;
  }

  bool get hasNotes {
    return activeNotes.isNotEmpty;
  }

  String get profileDisplayName {
    return authSession.value?.displayName ?? 'Piisiit Note User';
  }

  String get profileStatusText {
    final AuthSession? session = authSession.value;
    final String email = session?.email?.trim() ?? '';

    if (email.isNotEmpty) {
      return email;
    }

    final String phone = session?.phone?.trim() ?? '';
    return phone.isEmpty ? 'Signed in' : phone;
  }

  String? get profileAvatarUrl {
    final String value = authSession.value?.avatarUrl?.trim() ?? '';

    if (value.isEmpty) {
      return null;
    }

    final Uri? avatarUri = Uri.tryParse(value);
    if (avatarUri?.hasScheme == true) {
      return value;
    }

    final Uri? baseUri = Uri.tryParse(ApiConfig.authBaseUrl);
    return baseUri?.resolve(value).toString();
  }

  List<NoteEntity> get activeNotes {
    return notes
        .where((NoteEntity note) {
          return !note.isArchived && !note.isDeleted;
        })
        .toList(growable: false);
  }

  FolderEntity? get selectedFolder {
    final int? folderId = selectedFolderId.value;

    if (folderId == null) {
      return null;
    }

    return _findFolderById(folders, folderId);
  }

  String get selectedFolderName {
    final FolderEntity? folder = selectedFolder;

    if (folder == null) {
      return 'All Notes';
    }

    final String folderName = folder.name.trim();

    return folderName.isEmpty ? 'Unnamed Folder' : folderName;
  }

  int get selectedFolderNoteCount {
    final FolderEntity? folder = selectedFolder;

    if (folder != null) {
      return folder.noteCount;
    }

    final List<NoteEntity> activeNoteSnapshot = activeNotes;

    if (activeNoteSnapshot.isNotEmpty) {
      return activeNoteSnapshot.length;
    }

    return folders.fold<int>(0, (int total, FolderEntity folder) {
      return total + folder.noteCount;
    });
  }

  List<NoteEntity> get visibleNotes {
    final int? folderId = selectedFolderId.value;

    final List<NoteEntity> result;

    if (folderId == null) {
      result = activeNotes;
    } else {
      result = activeNotes.where((NoteEntity note) {
        return note.folderId == folderId;
      }).toList();
    }

    result.sort((NoteEntity first, NoteEntity second) {
      if (first.isPinned != second.isPinned) {
        return first.isPinned ? -1 : 1;
      }

      final int orderComparison = first.sortOrder.compareTo(second.sortOrder);

      if (orderComparison != 0) {
        return orderComparison;
      }

      final DateTime firstUpdatedAt =
          first.updatedAt ?? first.createdAt ?? DateTime(1970);
      final DateTime secondUpdatedAt =
          second.updatedAt ?? second.createdAt ?? DateTime(1970);

      final int updatedComparison = secondUpdatedAt.compareTo(firstUpdatedAt);

      if (updatedComparison != 0) {
        return updatedComparison;
      }

      return second.id.compareTo(first.id);
    });

    return result;
  }

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void onInit() {
    super.onInit();

    loadAll();
  }

  // ===========================================================================
  // LOAD DATA
  // ===========================================================================

  Future<void> loadAll() async {
    await Future.wait<void>(<Future<void>>[
      loadFolders(),
      loadNotes(),
      loadSession(),
    ]);
  }

  Future<void> loadSession() async {
    try {
      authSession.value = await authRepository.getSession();
    } catch (_) {
      // Folder and note refreshes must remain usable when profile metadata in
      // secure storage cannot be read on this device.
      authSession.value = null;
    }
  }

  /// Loads active and deleted folders from the folder API.
  ///
  /// A folder is considered deleted when the API puts it in `trash` or its
  /// DeletedAt value is not null.
  Future<void> loadFolders() async {
    final int loadGeneration = ++_folderLoadGeneration;

    try {
      isFoldersLoading.value = true;
      folderErrorMessage.value = '';

      final List<FolderEntity> apiResult = await folderRepository.getFolders();

      if (loadGeneration != _folderLoadGeneration) {
        return;
      }

      final List<FolderEntity> result = _applyPendingFolderOperations(
        apiResult,
      );

      final List<FolderEntity> activeFolders = result.where((
        FolderEntity folder,
      ) {
        return !folder.isDeleted;
      }).toList();

      final List<FolderEntity> apiDeletedFolders = result.where((
        FolderEntity folder,
      ) {
        return folder.isDeleted;
      }).toList();

      activeFolders.sort((FolderEntity first, FolderEntity second) {
        final int orderComparison = first.sortOrder.compareTo(second.sortOrder);

        if (orderComparison != 0) {
          return orderComparison;
        }

        return first.name.toLowerCase().compareTo(second.name.toLowerCase());
      });

      apiDeletedFolders.sort((FolderEntity first, FolderEntity second) {
        final DateTime firstDeletedAt =
            first.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        final DateTime secondDeletedAt =
            second.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return secondDeletedAt.compareTo(firstDeletedAt);
      });

      folders.assignAll(activeFolders);
      deletedFolders.assignAll(apiDeletedFolders);

      _validateSelectedFolder();
    } catch (error) {
      if (loadGeneration == _folderLoadGeneration) {
        folderErrorMessage.value = _cleanError(error);
      }
    } finally {
      if (loadGeneration == _folderLoadGeneration) {
        isFoldersLoading.value = false;
      }
    }
  }

  Future<void> loadNotes() async {
    final int loadGeneration = ++_noteLoadGeneration;

    try {
      isNotesLoading.value = true;
      noteErrorMessage.value = '';

      final List<NoteEntity> result = await noteRepository.getNotes();

      if (loadGeneration != _noteLoadGeneration) {
        return;
      }

      notes.assignAll(_applyPendingNoteStates(result));
    } catch (error) {
      if (loadGeneration == _noteLoadGeneration) {
        noteErrorMessage.value = _cleanError(error);
      }
    } finally {
      if (loadGeneration == _noteLoadGeneration) {
        isNotesLoading.value = false;
      }
    }
  }

  // ===========================================================================
  // FOLDER SELECTION
  // ===========================================================================

  void selectAllNotes() {
    selectedFolderId.value = null;
  }

  void selectFolder(int folderId) {
    if (folderId <= 0) {
      return;
    }

    final FolderEntity? folder = _findFolderById(folders, folderId);

    if (folder == null) {
      return;
    }

    selectedFolderId.value = folderId;
  }

  void _validateSelectedFolder() {
    final int? folderId = selectedFolderId.value;

    if (folderId == null) {
      return;
    }

    final FolderEntity? folder = _findFolderById(folders, folderId);

    if (folder == null) {
      selectedFolderId.value = null;
    }
  }

  // ===========================================================================
  // CREATE FOLDER
  // ===========================================================================

  Future<bool> createFolder({
    required String name,
    String iconName = 'folder',
    String colorValue = '#2196F3',
  }) async {
    final String cleanName = name.trim();

    if (cleanName.isEmpty) {
      folderErrorMessage.value = 'Please enter a folder name.';
      Get.snackbar(
        'Folder name required',
        'Please enter a folder name.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    try {
      folderErrorMessage.value = '';
      await folderRepository.saveFolder(
        id: 0,
        name: cleanName,
        iconName: iconName.trim().isEmpty ? 'folder' : iconName.trim(),
        colorValue: colorValue.trim().isEmpty ? '#2196F3' : colorValue.trim(),
        sortOrder: folders.length + 1,
      );

      await loadFolders();

      Get.snackbar(
        'Folder created',
        '$cleanName was created successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (error) {
      folderErrorMessage.value = _cleanError(error);
      Get.snackbar(
        'Create folder failed',
        folderErrorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }
  }

  // ===========================================================================
  // UPDATE FOLDER
  // ===========================================================================

  Future<bool> updateFolder({
    required FolderEntity folder,
    required String name,
    String? iconName,
    String? colorValue,
    int? sortOrder,
  }) async {
    final String cleanName = name.trim();

    if (cleanName.isEmpty) {
      folderErrorMessage.value = 'Please enter a folder name.';
      Get.snackbar(
        'Folder name required',
        'Please enter a folder name.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    try {
      folderErrorMessage.value = '';
      await folderRepository.saveFolder(
        id: folder.id,
        name: cleanName,
        iconName: iconName?.trim().isNotEmpty == true
            ? iconName!.trim()
            : folder.iconName,
        colorValue: colorValue?.trim().isNotEmpty == true
            ? colorValue!.trim()
            : folder.colorValue,
        sortOrder: sortOrder ?? folder.sortOrder,
      );

      await loadFolders();

      Get.snackbar(
        'Folder updated',
        '$cleanName was updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (error) {
      folderErrorMessage.value = _cleanError(error);
      Get.snackbar(
        'Update folder failed',
        folderErrorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }
  }

  // ===========================================================================
  // DELETE OR RESTORE FOLDER
  // ===========================================================================

  /// Sends this request to the API:
  ///
  /// POST /api/folder/delete-restore
  ///
  /// Delete:
  /// {
  ///   "id": folderId,
  ///   "isDelete": true
  /// }
  ///
  /// Restore:
  /// {
  ///   "id": folderId,
  ///   "isDelete": false
  /// }
  Future<bool> deleteOrRestoreFolder({
    required int folderId,
    required bool isDelete,
  }) async {
    if (folderId <= 0) {
      folderErrorMessage.value = 'The folder ID is invalid.';
      _showSnackbar('Invalid folder', 'The folder ID is invalid.');

      return false;
    }

    FolderEntity? targetFolder = _findFolderById(folders, folderId);

    targetFolder ??= _findFolderById(deletedFolders, folderId);

    if (targetFolder == null) {
      folderErrorMessage.value = 'The selected folder could not be found.';
      _showSnackbar(
        'Folder not found',
        'The selected folder could not be found.',
      );

      return false;
    }

    try {
      folderErrorMessage.value = '';
      /*
       * Call:
       * POST /api/folder/delete-restore
       */
      await folderRepository.deleteOrRestoreFolder(
        id: folderId,
        isDelete: isDelete,
      );

      /*
       * Update the interface immediately after the
       * API confirms the operation succeeded.
       */
      if (isDelete) {
        final FolderEntity deletedFolder = targetFolder.copyWith(
          deletedAt: DateTime.now(),
          isInTrash: true,
        );

        _pendingRestoredFolders.remove(folderId);

        _pendingDeletedFolders[folderId] = deletedFolder;

        folders.removeWhere((FolderEntity folder) {
          return folder.id == folderId;
        });

        deletedFolders.removeWhere((FolderEntity folder) {
          return folder.id == folderId;
        });

        deletedFolders.insert(0, deletedFolder);

        if (selectedFolderId.value == folderId) {
          selectedFolderId.value = null;
        }
      } else {
        final FolderEntity restoredFolder = targetFolder.copyWith(
          clearDeletedAt: true,
          isInTrash: false,
        );

        _pendingDeletedFolders.remove(folderId);

        _pendingRestoredFolders[folderId] = restoredFolder;

        deletedFolders.removeWhere((FolderEntity folder) {
          return folder.id == folderId;
        });

        folders.removeWhere((FolderEntity folder) {
          return folder.id == folderId;
        });

        folders.add(restoredFolder);

        _sortActiveFolders();
      }

      /*
       * Reload from the API.
       *
       * When GET /api/folder returns deleted folders
       * with DeletedAt not null, those records will be
       * stored in deletedFolders.
       */
      await loadFolders();

      /*
       * Folder changes may change note visibility.
       * A note API problem should not undo a successful
       * folder operation.
       */
      try {
        await loadNotes();
      } catch (_) {
        // Folder operation remains successful.
      }

      _showSnackbar(
        isDelete ? 'Folder deleted' : 'Folder restored',
        isDelete
            ? 'The folder was moved to Recently Deleted.'
            : 'The folder was restored successfully.',
      );

      return true;
    } catch (error) {
      folderErrorMessage.value = _cleanError(error);
      _showSnackbar(
        isDelete ? 'Delete folder failed' : 'Restore folder failed',
        folderErrorMessage.value,
      );

      return false;
    }
  }

  // ===========================================================================
  // CREATE NOTE
  // ===========================================================================

  Future<void> createNote({required String title}) async {
    final String cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      noteErrorMessage.value = 'Please enter a note title.';
      Get.snackbar(
        'Note title required',
        'Please enter a note title.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    if (folders.isEmpty) {
      noteErrorMessage.value = 'Create a folder before creating a note.';
      Get.snackbar(
        'Folder required',
        'Create a folder before creating a note.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    try {
      noteErrorMessage.value = '';
      final int folderId = selectedFolderId.value ?? folders.first.id;

      final int noteId = await noteRepository.saveNote(
        noteId: 0,
        folderId: folderId,
        title: cleanTitle,
      );

      if (noteId <= 0) {
        throw StateError('The API did not return a valid note ID.');
      }

      await Get.toNamed(AppRoutes.noteEditor, arguments: noteId);

      await loadAll();
    } catch (error) {
      noteErrorMessage.value = _cleanError(error);
      Get.snackbar(
        'Create note failed',
        noteErrorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ===========================================================================
  // OPEN NOTE
  // ===========================================================================

  Future<void> openNote(int noteId) async {
    if (noteId <= 0) {
      return;
    }

    await Get.toNamed(AppRoutes.noteEditor, arguments: noteId);

    await loadAll();
  }

  // ===========================================================================
  // NOTE STATE
  // ===========================================================================

  Future<void> togglePin(NoteEntity note) async {
    await _updateNoteState(
      note,
      updated: note.copyWith(
        isPinned: !note.isPinned,
        pinnedAt: note.isPinned ? null : DateTime.now(),
        clearPinnedAt: note.isPinned,
      ),
      changedField: NoteStateField.pinned,
      failureTitle: 'Update note failed',
    );
  }

  Future<void> archiveNote(NoteEntity note) async {
    final bool succeeded = await _updateNoteState(
      note,
      updated: note.copyWith(isArchived: !note.isArchived),
      changedField: NoteStateField.archived,
      failureTitle: 'Archive update failed',
    );

    if (succeeded) {
      _showSnackbar(
        note.isArchived ? 'Note restored' : 'Note archived',
        note.isArchived
            ? 'The note was removed from the archive.'
            : 'The note was archived successfully.',
      );
    }
  }

  Future<bool> restoreArchivedNote(NoteEntity note) async {
    if (!note.isArchived) {
      return true;
    }

    final bool succeeded = await _updateNoteState(
      note,
      updated: note.copyWith(isArchived: false),
      changedField: NoteStateField.archived,
      failureTitle: 'Restore note failed',
    );

    if (succeeded) {
      _showSnackbar('Note restored', 'The note was removed from the archive.');
    }

    return succeeded;
  }

  Future<void> lockNote(NoteEntity note) async {
    final bool succeeded = await _updateNoteState(
      note,
      updated: note.copyWith(isLocked: !note.isLocked),
      changedField: NoteStateField.locked,
      failureTitle: 'Lock update failed',
    );

    if (succeeded) {
      _showSnackbar(
        note.isLocked ? 'Note unlocked' : 'Note locked',
        note.isLocked ? 'The note was unlocked.' : 'The note was locked.',
      );
    }
  }

  Future<bool> _updateNoteState(
    NoteEntity current, {
    required NoteEntity updated,
    required NoteStateField changedField,
    required String failureTitle,
  }) async {
    if (current.id <= 0 || noteIdsBeingUpdated.contains(current.id)) {
      return false;
    }

    try {
      noteIdsBeingUpdated.add(current.id);
      noteErrorMessage.value = '';

      await noteRepository.updateState(
        noteId: current.id,
        isPinned: updated.isPinned,
        isArchived: updated.isArchived,
        isLocked: updated.isLocked,
        changedField: changedField,
      );

      final NoteEntity confirmed = updated.copyWith(updatedAt: DateTime.now());
      _pendingNoteStates[current.id] = confirmed;
      _replaceNote(confirmed);

      await loadNotes();

      return true;
    } catch (error) {
      noteErrorMessage.value = _cleanError(error);
      _showSnackbar(failureTitle, noteErrorMessage.value);
      return false;
    } finally {
      noteIdsBeingUpdated.remove(current.id);
    }
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  Future<void> logout() async {
    try {
      await authRepository.logout();
    } finally {
      folders.clear();
      deletedFolders.clear();
      notes.clear();
      authSession.value = null;

      _pendingDeletedFolders.clear();
      _pendingRestoredFolders.clear();
      _pendingNoteStates.clear();
      noteIdsBeingUpdated.clear();

      selectedFolderId.value = null;

      Get.offAllNamed(AppRoutes.login);
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  List<NoteEntity> _applyPendingNoteStates(List<NoteEntity> apiNotes) {
    final List<NoteEntity> reconciled = <NoteEntity>[];
    final Set<int> seenIds = <int>{};

    for (final NoteEntity apiNote in apiNotes) {
      seenIds.add(apiNote.id);

      final NoteEntity? pending = _pendingNoteStates[apiNote.id];

      if (pending == null) {
        reconciled.add(apiNote);
        continue;
      }

      final bool apiConfirmed =
          apiNote.isPinned == pending.isPinned &&
          apiNote.isArchived == pending.isArchived &&
          apiNote.isLocked == pending.isLocked;

      if (apiConfirmed) {
        _pendingNoteStates.remove(apiNote.id);
        reconciled.add(apiNote);
      } else {
        reconciled.add(
          apiNote.copyWith(
            isPinned: pending.isPinned,
            isArchived: pending.isArchived,
            isLocked: pending.isLocked,
            pinnedAt: pending.pinnedAt,
            clearPinnedAt: pending.pinnedAt == null,
            updatedAt: pending.updatedAt,
          ),
        );
      }
    }

    for (final NoteEntity pending in _pendingNoteStates.values) {
      if (seenIds.add(pending.id)) {
        reconciled.add(pending);
      }
    }

    return reconciled;
  }

  void _replaceNote(NoteEntity updated) {
    final int index = notes.indexWhere((NoteEntity note) {
      return note.id == updated.id;
    });

    if (index >= 0) {
      notes[index] = updated;
    } else {
      notes.add(updated);
    }
  }

  void _showSnackbar(String title, String message) {
    if (Get.testMode || Get.context == null) {
      return;
    }

    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  List<FolderEntity> _applyPendingFolderOperations(
    List<FolderEntity> apiFolders,
  ) {
    final List<FolderEntity> reconciledFolders = <FolderEntity>[];

    final Set<int> seenFolderIds = <int>{};

    for (final FolderEntity apiFolder in apiFolders) {
      seenFolderIds.add(apiFolder.id);

      final FolderEntity? pendingDeleted = _pendingDeletedFolders[apiFolder.id];

      if (pendingDeleted != null) {
        if (apiFolder.isDeleted) {
          _pendingDeletedFolders.remove(apiFolder.id);

          reconciledFolders.add(apiFolder);
        } else {
          /*
           * The delete POST succeeded but this GET is stale. Do not move the
           * folder back into the active list.
           */
          reconciledFolders.add(pendingDeleted);
        }

        continue;
      }

      final FolderEntity? pendingRestored =
          _pendingRestoredFolders[apiFolder.id];

      if (pendingRestored != null) {
        if (!apiFolder.isDeleted) {
          _pendingRestoredFolders.remove(apiFolder.id);

          reconciledFolders.add(apiFolder);
        } else {
          /*
           * The restore POST succeeded but trash has not caught up yet.
           */
          reconciledFolders.add(pendingRestored);
        }

        continue;
      }

      reconciledFolders.add(apiFolder);
    }

    for (final FolderEntity folder in _pendingDeletedFolders.values) {
      if (seenFolderIds.add(folder.id)) {
        reconciledFolders.add(folder);
      }
    }

    for (final FolderEntity folder in _pendingRestoredFolders.values) {
      if (seenFolderIds.add(folder.id)) {
        reconciledFolders.add(folder);
      }
    }

    return reconciledFolders;
  }

  FolderEntity? _findFolderById(Iterable<FolderEntity> source, int folderId) {
    for (final FolderEntity folder in source) {
      if (folder.id == folderId) {
        return folder;
      }
    }

    return null;
  }

  void _sortActiveFolders() {
    final List<FolderEntity> sorted = folders.toList();

    sorted.sort((FolderEntity first, FolderEntity second) {
      final int orderComparison = first.sortOrder.compareTo(second.sortOrder);

      if (orderComparison != 0) {
        return orderComparison;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    folders.assignAll(sorted);
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }
}
