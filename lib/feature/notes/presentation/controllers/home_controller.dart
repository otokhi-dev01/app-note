import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../folders/domain/repositories/folder_repository.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';

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

  final RxList<FolderEntity> folders =
      <FolderEntity>[].obs;

  final RxList<FolderEntity> deletedFolders =
      <FolderEntity>[].obs;

  final RxList<NoteEntity> notes =
      <NoteEntity>[].obs;

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
        (isFoldersLoading.value ||
            isNotesLoading.value);
  }

  bool get hasFolderError {
    return folderErrorMessage.value
        .trim()
        .isNotEmpty;
  }

  bool get hasNoteError {
    return noteErrorMessage.value
        .trim()
        .isNotEmpty;
  }

  bool get hasFolders {
    return folders.isNotEmpty;
  }

  bool get hasDeletedFolders {
    return deletedFolders.isNotEmpty;
  }

  bool get hasNotes {
    return notes.isNotEmpty;
  }

  FolderEntity? get selectedFolder {
    final int? folderId =
        selectedFolderId.value;

    if (folderId == null) {
      return null;
    }

    return _findFolderById(
      folders,
      folderId,
    );
  }

  String get selectedFolderName {
    final FolderEntity? folder =
        selectedFolder;

    if (folder == null) {
      return 'All Notes';
    }

    final String folderName =
    folder.name.trim();

    return folderName.isEmpty
        ? 'Unnamed Folder'
        : folderName;
  }

  int get selectedFolderNoteCount {
    final FolderEntity? folder =
        selectedFolder;

    if (folder != null) {
      return folder.noteCount;
    }

    if (notes.isNotEmpty) {
      return notes.length;
    }

    return folders.fold<int>(
      0,
          (
          int total,
          FolderEntity folder,
          ) {
        return total + folder.noteCount;
      },
    );
  }

  List<NoteEntity> get visibleNotes {
    final int? folderId =
        selectedFolderId.value;

    final List<NoteEntity> result;

    if (folderId == null) {
      result = notes.toList();
    } else {
      result = notes.where(
            (NoteEntity note) {
          return note.folderId == folderId;
        },
      ).toList();
    }

    result.sort(
          (
          NoteEntity first,
          NoteEntity second,
          ) {
        if (first.isPinned != second.isPinned) {
          return first.isPinned ? -1 : 1;
        }

        return second.id.compareTo(first.id);
      },
    );

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
    await Future.wait<void>(
      <Future<void>>[
        loadFolders(),
        loadNotes(),
      ],
    );
  }

  /// Loads active and deleted folders from the folder API.
  ///
  /// A folder is considered deleted when its DeletedAt value is not null.
  Future<void> loadFolders() async {
    try {
      isFoldersLoading.value = true;
      folderErrorMessage.value = '';

      final List<FolderEntity> result =
      await folderRepository.getFolders();

      final List<FolderEntity> activeFolders =
      result.where(
            (FolderEntity folder) {
          return folder.deletedAt == null;
        },
      ).toList();

      final List<FolderEntity> apiDeletedFolders =
      result.where(
            (FolderEntity folder) {
          return folder.deletedAt != null;
        },
      ).toList();

      activeFolders.sort(
            (
            FolderEntity first,
            FolderEntity second,
            ) {
          final int orderComparison =
          first.sortOrder.compareTo(
            second.sortOrder,
          );

          if (orderComparison != 0) {
            return orderComparison;
          }

          return first.name
              .toLowerCase()
              .compareTo(
            second.name.toLowerCase(),
          );
        },
      );

      apiDeletedFolders.sort(
            (
            FolderEntity first,
            FolderEntity second,
            ) {
          final DateTime firstDeletedAt =
              first.deletedAt ??
                  DateTime.fromMillisecondsSinceEpoch(
                    0,
                  );

          final DateTime secondDeletedAt =
              second.deletedAt ??
                  DateTime.fromMillisecondsSinceEpoch(
                    0,
                  );

          return secondDeletedAt.compareTo(
            firstDeletedAt,
          );
        },
      );

      folders.assignAll(activeFolders);

      /*
       * When the API returns deleted folders, use the API
       * as the final source of truth.
       */
      if (apiDeletedFolders.isNotEmpty) {
        deletedFolders.assignAll(
          apiDeletedFolders,
        );
      } else {
        /*
         * Some APIs return active folders only.
         *
         * Keep deleted folders in memory for the current
         * application session, but remove folders that the
         * API now reports as active. This also handles restore.
         */
        final Set<int> activeFolderIds =
        activeFolders
            .map(
              (FolderEntity folder) {
            return folder.id;
          },
        )
            .toSet();

        deletedFolders.removeWhere(
              (FolderEntity folder) {
            return activeFolderIds.contains(
              folder.id,
            );
          },
        );
      }

      _validateSelectedFolder();
    } catch (error) {
      folderErrorMessage.value =
          _cleanError(error);
    } finally {
      isFoldersLoading.value = false;
    }
  }

  Future<void> loadNotes() async {
    try {
      isNotesLoading.value = true;
      noteErrorMessage.value = '';

      final List<NoteEntity> result =
      await noteRepository.getNotes();

      notes.assignAll(result);
    } catch (error) {
      noteErrorMessage.value =
          _cleanError(error);
    } finally {
      isNotesLoading.value = false;
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

    final FolderEntity? folder =
    _findFolderById(
      folders,
      folderId,
    );

    if (folder == null) {
      return;
    }

    selectedFolderId.value = folderId;
  }

  void _validateSelectedFolder() {
    final int? folderId =
        selectedFolderId.value;

    if (folderId == null) {
      return;
    }

    final FolderEntity? folder =
    _findFolderById(
      folders,
      folderId,
    );

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
      Get.snackbar(
        'Folder name required',
        'Please enter a folder name.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    try {
      await folderRepository.saveFolder(
        id: 0,
        name: cleanName,
        iconName: iconName.trim().isEmpty
            ? 'folder'
            : iconName.trim(),
        colorValue: colorValue.trim().isEmpty
            ? '#2196F3'
            : colorValue.trim(),
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
      Get.snackbar(
        'Create folder failed',
        _cleanError(error),
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
      Get.snackbar(
        'Folder name required',
        'Please enter a folder name.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    try {
      await folderRepository.saveFolder(
        id: folder.id,
        name: cleanName,
        iconName:
        iconName?.trim().isNotEmpty == true
            ? iconName!.trim()
            : folder.iconName,
        colorValue:
        colorValue?.trim().isNotEmpty == true
            ? colorValue!.trim()
            : folder.colorValue,
        sortOrder:
        sortOrder ?? folder.sortOrder,
      );

      await loadFolders();

      Get.snackbar(
        'Folder updated',
        '$cleanName was updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (error) {
      Get.snackbar(
        'Update folder failed',
        _cleanError(error),
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
      Get.snackbar(
        'Invalid folder',
        'The folder ID is invalid.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    FolderEntity? targetFolder =
    _findFolderById(
      folders,
      folderId,
    );

    targetFolder ??= _findFolderById(
      deletedFolders,
      folderId,
    );

    if (targetFolder == null) {
      Get.snackbar(
        'Folder not found',
        'The selected folder could not be found.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }

    try {
      /*
       * Call:
       * POST /api/folder/delete-restore
       */
      await folderRepository
          .deleteOrRestoreFolder(
        id: folderId,
        isDelete: isDelete,
      );

      /*
       * Update the interface immediately after the
       * API confirms the operation succeeded.
       */
      if (isDelete) {
        folders.removeWhere(
              (FolderEntity folder) {
            return folder.id == folderId;
          },
        );

        deletedFolders.removeWhere(
              (FolderEntity folder) {
            return folder.id == folderId;
          },
        );

        deletedFolders.insert(
          0,
          targetFolder.copyWith(
            deletedAt: DateTime.now(),
          ),
        );

        if (selectedFolderId.value ==
            folderId) {
          selectedFolderId.value = null;
        }
      } else {
        deletedFolders.removeWhere(
              (FolderEntity folder) {
            return folder.id == folderId;
          },
        );

        folders.removeWhere(
              (FolderEntity folder) {
            return folder.id == folderId;
          },
        );

        folders.add(
          targetFolder.copyWith(
            clearDeletedAt: true,
          ),
        );

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

      Get.snackbar(
        isDelete
            ? 'Folder deleted'
            : 'Folder restored',
        isDelete
            ? 'The folder was moved to Recently Deleted.'
            : 'The folder was restored successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (error) {
      Get.snackbar(
        isDelete
            ? 'Delete folder failed'
            : 'Restore folder failed',
        _cleanError(error),
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }
  }

  // ===========================================================================
  // CREATE NOTE
  // ===========================================================================

  Future<void> createNote({
    required String title,
  }) async {
    final String cleanTitle =
    title.trim();

    if (cleanTitle.isEmpty) {
      Get.snackbar(
        'Note title required',
        'Please enter a note title.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    if (folders.isEmpty) {
      Get.snackbar(
        'Folder required',
        'Create a folder before creating a note.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    try {
      final int folderId =
          selectedFolderId.value ??
              folders.first.id;

      final int noteId =
      await noteRepository.saveNote(
        noteId: 0,
        folderId: folderId,
        title: cleanTitle,
      );

      if (noteId <= 0) {
        throw StateError(
          'The API did not return a valid note ID.',
        );
      }

      await Get.toNamed(
        AppRoutes.noteEditor,
        arguments: noteId,
      );

      await loadAll();
    } catch (error) {
      Get.snackbar(
        'Create note failed',
        _cleanError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ===========================================================================
  // OPEN NOTE
  // ===========================================================================

  Future<void> openNote(
      int noteId,
      ) async {
    if (noteId <= 0) {
      return;
    }

    await Get.toNamed(
      AppRoutes.noteEditor,
      arguments: noteId,
    );

    await loadAll();
  }

  // ===========================================================================
  // NOTE STATE
  // ===========================================================================

  Future<void> togglePin(
      NoteEntity note,
      ) async {
    try {
      await noteRepository.updateState(
        noteId: note.id,
        isPinned: !note.isPinned,
        isArchived: note.isArchived,
        isLocked: note.isLocked,
      );

      await loadNotes();
    } catch (error) {
      Get.snackbar(
        'Update note failed',
        _cleanError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> archiveNote(
      NoteEntity note,
      ) async {
    try {
      await noteRepository.updateState(
        noteId: note.id,
        isPinned: note.isPinned,
        isArchived: !note.isArchived,
        isLocked: note.isLocked,
      );

      await loadNotes();

      Get.snackbar(
        note.isArchived
            ? 'Note restored'
            : 'Note archived',
        note.isArchived
            ? 'The note was removed from the archive.'
            : 'The note was archived successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Archive update failed',
        _cleanError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> lockNote(
      NoteEntity note,
      ) async {
    try {
      await noteRepository.updateState(
        noteId: note.id,
        isPinned: note.isPinned,
        isArchived: note.isArchived,
        isLocked: !note.isLocked,
      );

      await loadNotes();

      Get.snackbar(
        note.isLocked
            ? 'Note unlocked'
            : 'Note locked',
        note.isLocked
            ? 'The note was unlocked.'
            : 'The note was locked.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Lock update failed',
        _cleanError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
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

      selectedFolderId.value = null;

      Get.offAllNamed(
        AppRoutes.login,
      );
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  FolderEntity? _findFolderById(
      Iterable<FolderEntity> source,
      int folderId,
      ) {
    for (final FolderEntity folder
    in source) {
      if (folder.id == folderId) {
        return folder;
      }
    }

    return null;
  }

  void _sortActiveFolders() {
    final List<FolderEntity> sorted =
    folders.toList();

    sorted.sort(
          (
          FolderEntity first,
          FolderEntity second,
          ) {
        final int orderComparison =
        first.sortOrder.compareTo(
          second.sortOrder,
        );

        if (orderComparison != 0) {
          return orderComparison;
        }

        return first.name
            .toLowerCase()
            .compareTo(
          second.name.toLowerCase(),
        );
      },
    );

    folders.assignAll(sorted);
  }

  String _cleanError(
      Object error,
      ) {
    return error
        .toString()
        .replaceFirst(
      'ApiException: ',
      '',
    )
        .replaceFirst(
      'StateError: ',
      '',
    )
        .replaceFirst(
      'Bad state: ',
      '',
    )
        .replaceFirst(
      'Exception: ',
      '',
    )
        .trim();
  }
}