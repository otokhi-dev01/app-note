import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../folders/domain/repositories/folder_repository_impl.dart';
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

  // ---------------------------------------------------------------------------
  // Active data
  // ---------------------------------------------------------------------------

  final RxList<FolderEntity> folders =
      <FolderEntity>[].obs;

  final RxList<NoteEntity> notes =
      <NoteEntity>[].obs;

  // ---------------------------------------------------------------------------
  // Deleted and archived data
  // ---------------------------------------------------------------------------

  final RxList<FolderEntity> deletedFolders =
      <FolderEntity>[].obs;

  final RxList<NoteEntity> archivedNotes =
      <NoteEntity>[].obs;

  // null means "All Notes".
  final RxnInt selectedFolderId = RxnInt();

  // ---------------------------------------------------------------------------
  // Loading states
  // ---------------------------------------------------------------------------

  final RxBool isFoldersLoading = false.obs;
  final RxBool isNotesLoading = false.obs;

  // ---------------------------------------------------------------------------
  // Error states
  // ---------------------------------------------------------------------------

  final RxString folderErrorMessage = ''.obs;
  final RxString noteErrorMessage = ''.obs;

  // ---------------------------------------------------------------------------
  // Computed states
  // ---------------------------------------------------------------------------

  bool get isInitialLoading {
    return folders.isEmpty &&
        notes.isEmpty &&
        (isFoldersLoading.value ||
            isNotesLoading.value);
  }

  bool get hasFolderError {
    return folderErrorMessage.value.isNotEmpty;
  }

  bool get hasNoteError {
    return noteErrorMessage.value.isNotEmpty;
  }

  bool get hasFolders {
    return folders.isNotEmpty;
  }

  bool get hasNotes {
    return notes.isNotEmpty;
  }

  bool get hasDeletedFolders {
    return deletedFolders.isNotEmpty;
  }

  bool get hasArchivedNotes {
    return archivedNotes.isNotEmpty;
  }

  bool get isRecycleBinEmpty {
    return deletedFolders.isEmpty &&
        archivedNotes.isEmpty;
  }

  int get recycleBinItemCount {
    return deletedFolders.length +
        archivedNotes.length;
  }

  int get totalNoteCount {
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

  FolderEntity? get selectedFolder {
    final int? folderId =
        selectedFolderId.value;

    if (folderId == null) {
      return null;
    }

    for (final FolderEntity folder in folders) {
      if (folder.id == folderId) {
        return folder;
      }
    }

    return null;
  }

  String get selectedFolderName {
    final FolderEntity? folder =
        selectedFolder;

    if (folder == null) {
      return 'All Notes';
    }

    final String folderName =
    folder.name.trim();

    if (folderName.isEmpty) {
      return 'Unnamed Folder';
    }

    return folderName;
  }

  int get selectedFolderNoteCount {
    final FolderEntity? folder =
        selectedFolder;

    if (folder != null) {
      return folder.noteCount;
    }

    return totalNoteCount;
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
        if (first.isPinned ==
            second.isPinned) {
          return 0;
        }

        return first.isPinned ? -1 : 1;
      },
    );

    return result;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    loadAll();
  }

  // ---------------------------------------------------------------------------
  // Load all data
  // ---------------------------------------------------------------------------

  Future<void> loadAll() async {
    await Future.wait<void>(
      <Future<void>>[
        loadFolders(),
        loadNotes(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Load folders
  // ---------------------------------------------------------------------------

  Future<void> loadFolders() async {
    try {
      isFoldersLoading.value = true;
      folderErrorMessage.value = '';

      final List<FolderEntity> result =
      await folderRepository.getFolders();

      result.sort(
            (
            FolderEntity first,
            FolderEntity second,
            ) {
          return first.sortOrder.compareTo(
            second.sortOrder,
          );
        },
      );

      final List<FolderEntity> activeItems =
      result.where(
            (FolderEntity folder) {
          return folder.deletedAt == null;
        },
      ).toList();

      final List<FolderEntity> deletedItems =
      result.where(
            (FolderEntity folder) {
          return folder.deletedAt != null;
        },
      ).toList();

      folders.assignAll(activeItems);

      /*
       * When the API returns deleted folders, use them as
       * the source of truth.
       *
       * When the API only returns active folders, preserve
       * the local deleted-folder cache during this session.
       */
      if (deletedItems.isNotEmpty) {
        deletedFolders.assignAll(
          deletedItems,
        );
      } else {
        deletedFolders.removeWhere(
              (FolderEntity deletedFolder) {
            return activeItems.any(
                  (FolderEntity activeFolder) {
                return activeFolder.id ==
                    deletedFolder.id;
              },
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

  // ---------------------------------------------------------------------------
  // Load notes
  // ---------------------------------------------------------------------------

  Future<void> loadNotes() async {
    try {
      isNotesLoading.value = true;
      noteErrorMessage.value = '';

      final List<NoteEntity> result =
      await noteRepository.getNotes();

      final List<NoteEntity> activeItems =
      result.where(
            (NoteEntity note) {
          return !note.isArchived;
        },
      ).toList();

      final List<NoteEntity> archivedItems =
      result.where(
            (NoteEntity note) {
          return note.isArchived;
        },
      ).toList();

      notes.assignAll(activeItems);

      /*
       * When the API returns archived notes, use them.
       *
       * When it only returns active notes, preserve the local
       * archived-note cache during the current app session.
       */
      if (archivedItems.isNotEmpty) {
        archivedNotes.assignAll(
          archivedItems,
        );
      } else {
        archivedNotes.removeWhere(
              (NoteEntity archivedNote) {
            return activeItems.any(
                  (NoteEntity activeNote) {
                return activeNote.id ==
                    archivedNote.id;
              },
            );
          },
        );
      }
    } catch (error) {
      // Keep currently displayed notes when refresh fails.
      noteErrorMessage.value =
          _cleanError(error);
    } finally {
      isNotesLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Folder selection
  // ---------------------------------------------------------------------------

  void selectAllNotes() {
    selectedFolderId.value = null;
  }

  void selectFolder(int folderId) {
    final bool folderExists =
    folders.any(
          (FolderEntity folder) {
        return folder.id == folderId;
      },
    );

    if (!folderExists) {
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

    final bool folderStillExists =
    folders.any(
          (FolderEntity folder) {
        return folder.id == folderId;
      },
    );

    if (!folderStillExists) {
      selectedFolderId.value = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Create folder
  // ---------------------------------------------------------------------------

  Future<bool> createFolder({
    required String name,
    String iconName = 'folder',
    String colorValue = '#5B7CFA',
  }) async {
    final String cleanName = name.trim();
    final String cleanIconName =
    iconName.trim();
    final String cleanColorValue =
    colorValue.trim();

    if (cleanName.isEmpty) {
      Get.snackbar(
        'Folder name required',
        'Please enter a folder name.',
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return false;
    }

    try {
      await folderRepository.saveFolder(
        id: 0,
        name: cleanName,
        iconName: cleanIconName.isEmpty
            ? 'folder'
            : cleanIconName,
        colorValue: cleanColorValue.isEmpty
            ? '#5B7CFA'
            : cleanColorValue,
        sortOrder: folders.length + 1,
      );

      await loadFolders();

      Get.snackbar(
        'Folder created',
        '$cleanName was created successfully.',
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return true;
    } catch (error) {
      Get.snackbar(
        'Create folder failed',
        _cleanError(error),
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Update folder
  // ---------------------------------------------------------------------------

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
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return false;
    }

    try {
      final String newIconName =
          iconName?.trim() ?? '';

      final String newColorValue =
          colorValue?.trim() ?? '';

      await folderRepository.saveFolder(
        id: folder.id,
        name: cleanName,
        iconName: newIconName.isEmpty
            ? folder.iconName
            : newIconName,
        colorValue: newColorValue.isEmpty
            ? folder.colorValue
            : newColorValue,
        sortOrder:
        sortOrder ?? folder.sortOrder,
      );

      await loadFolders();

      Get.snackbar(
        'Folder updated',
        '$cleanName was updated successfully.',
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return true;
    } catch (error) {
      Get.snackbar(
        'Update folder failed',
        _cleanError(error),
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Delete or restore folder
  // ---------------------------------------------------------------------------

  Future<bool> deleteOrRestoreFolder({
    required int folderId,
    required bool isDelete,
  }) async {
    FolderEntity? folderSnapshot;

    if (isDelete) {
      folderSnapshot = _findFolderById(
        folders,
        folderId,
      );
    } else {
      folderSnapshot = _findFolderById(
        deletedFolders,
        folderId,
      );
    }

    try {
      await folderRepository
          .deleteOrRestoreFolder(
        id: folderId,
        isDelete: isDelete,
      );

      if (isDelete) {
        if (selectedFolderId.value ==
            folderId) {
          selectedFolderId.value = null;
        }

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

        if (folderSnapshot != null) {
          deletedFolders.add(
            _copyFolder(
              folderSnapshot,
              deletedAt: DateTime.now(),
            ),
          );
        }
      } else {
        deletedFolders.removeWhere(
              (FolderEntity folder) {
            return folder.id == folderId;
          },
        );

        if (folderSnapshot != null) {
          folders.removeWhere(
                (FolderEntity folder) {
              return folder.id == folderId;
            },
          );

          folders.add(
            _copyFolder(
              folderSnapshot,
              deletedAt: null,
            ),
          );

          folders.sort(
                (
                FolderEntity first,
                FolderEntity second,
                ) {
              return first.sortOrder.compareTo(
                second.sortOrder,
              );
            },
          );
        }
      }

      await Future.wait<void>(
        <Future<void>>[
          loadFolders(),
          loadNotes(),
        ],
      );

      Get.snackbar(
        isDelete
            ? 'Folder deleted'
            : 'Folder restored',
        isDelete
            ? 'The folder was moved to the recycle bin.'
            : 'The folder was restored successfully.',
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return true;
    } catch (error) {
      Get.snackbar(
        isDelete
            ? 'Delete folder failed'
            : 'Restore folder failed',
        _cleanError(error),
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Create note
  // ---------------------------------------------------------------------------

  Future<int?> createNote({
    required String title,
    int? folderId,
    bool openEditor = true,
  }) async {
    final String cleanTitle =
    title.trim();

    if (cleanTitle.isEmpty) {
      Get.snackbar(
        'Note title required',
        'Please enter a note title.',
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return null;
    }

    if (folders.isEmpty) {
      Get.snackbar(
        'Folder required',
        'Create a folder before creating a note.',
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return null;
    }

    final int targetFolderId =
        folderId ??
            selectedFolderId.value ??
            folders.first.id;

    final bool folderExists =
    folders.any(
          (FolderEntity folder) {
        return folder.id ==
            targetFolderId;
      },
    );

    if (!folderExists) {
      Get.snackbar(
        'Folder unavailable',
        'The selected folder no longer exists.',
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return null;
    }

    try {
      final int noteId =
      await noteRepository.saveNote(
        noteId: 0,
        folderId: targetFolderId,
        title: cleanTitle,
      );

      selectedFolderId.value =
          targetFolderId;

      await Future.wait<void>(
        <Future<void>>[
          loadFolders(),
          loadNotes(),
        ],
      );

      if (openEditor) {
        await Get.toNamed(
          AppRoutes.noteEditor,
          arguments: noteId,
        );

        await Future.wait<void>(
          <Future<void>>[
            loadFolders(),
            loadNotes(),
          ],
        );
      }

      return noteId;
    } catch (error) {
      Get.snackbar(
        'Create note failed',
        _cleanError(error),
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Open note
  // ---------------------------------------------------------------------------

  Future<void> openNote(
      int noteId,
      ) async {
    await Get.toNamed(
      AppRoutes.noteEditor,
      arguments: noteId,
    );

    await Future.wait<void>(
      <Future<void>>[
        loadNotes(),
        loadFolders(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pin or unpin note
  // ---------------------------------------------------------------------------

  Future<bool> togglePin(
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

      return true;
    } catch (error) {
      Get.snackbar(
        'Update note failed',
        _cleanError(error),
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Archive or restore note
  // ---------------------------------------------------------------------------

  Future<bool> archiveNote(
      NoteEntity note,
      ) async {
    final bool willArchive =
    !note.isArchived;

    try {
      await noteRepository.updateState(
        noteId: note.id,
        isPinned: note.isPinned,
        isArchived: willArchive,
        isLocked: note.isLocked,
      );

      notes.removeWhere(
            (NoteEntity currentNote) {
          return currentNote.id ==
              note.id;
        },
      );

      archivedNotes.removeWhere(
            (NoteEntity currentNote) {
          return currentNote.id ==
              note.id;
        },
      );

      if (willArchive) {
        archivedNotes.add(
          _copyNote(
            note,
            isArchived: true,
          ),
        );
      } else {
        notes.add(
          _copyNote(
            note,
            isArchived: false,
          ),
        );
      }

      await Future.wait<void>(
        <Future<void>>[
          loadNotes(),
          loadFolders(),
        ],
      );

      Get.snackbar(
        willArchive
            ? 'Note archived'
            : 'Note restored',
        willArchive
            ? 'The note was moved to the recycle bin.'
            : 'The note was restored successfully.',
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return true;
    } catch (error) {
      Get.snackbar(
        willArchive
            ? 'Archive note failed'
            : 'Restore note failed',
        _cleanError(error),
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Lock or unlock note
  // ---------------------------------------------------------------------------

  Future<bool> lockNote(
      NoteEntity note,
      ) async {
    final bool willLock =
    !note.isLocked;

    try {
      await noteRepository.updateState(
        noteId: note.id,
        isPinned: note.isPinned,
        isArchived: note.isArchived,
        isLocked: willLock,
      );

      await loadNotes();

      Get.snackbar(
        willLock
            ? 'Note locked'
            : 'Note unlocked',
        willLock
            ? 'The note was locked successfully.'
            : 'The note was unlocked successfully.',
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return true;
    } catch (error) {
      Get.snackbar(
        'Lock update failed',
        _cleanError(error),
        snackPosition:
        SnackPosition.BOTTOM,
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Recycle bin
  // ---------------------------------------------------------------------------

  Future<void> refreshRecycleBin() async {
    await loadAll();
  }

  Future<bool> restoreFolder(
      FolderEntity folder,
      ) {
    return deleteOrRestoreFolder(
      folderId: folder.id,
      isDelete: false,
    );
  }

  Future<bool> restoreNote(
      NoteEntity note,
      ) {
    if (!note.isArchived) {
      return Future<bool>.value(false);
    }

    return archiveNote(note);
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    try {
      await authRepository.logout();
    } finally {
      folders.clear();
      notes.clear();
      deletedFolders.clear();
      archivedNotes.clear();

      selectedFolderId.value = null;

      Get.offAllNamed(
        AppRoutes.login,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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

  FolderEntity _copyFolder(
      FolderEntity folder, {
        required DateTime? deletedAt,
      }) {
    return FolderEntity(
      id: folder.id,
      userId: folder.userId,
      name: folder.name,
      iconName: folder.iconName,
      colorValue: folder.colorValue,
      sortOrder: folder.sortOrder,
      noteCount: folder.noteCount,
      createdAt: folder.createdAt,
      updatedAt: folder.updatedAt,
      deletedAt: deletedAt,
    );
  }

  NoteEntity _copyNote(
      NoteEntity note, {
        bool? isPinned,
        bool? isArchived,
        bool? isLocked,
      }) {
    return NoteEntity(
      id: note.id,
      folderId: note.folderId,
      title: note.title,
      content: note.content,
      isPinned:
      isPinned ?? note.isPinned,
      isArchived:
      isArchived ?? note.isArchived,
      isLocked:
      isLocked ?? note.isLocked,
    );
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
        .trim();
  }
}