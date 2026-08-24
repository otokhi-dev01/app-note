import 'package:get/get.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_dialogs.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/network/api_capabilities.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';

class RecentlyDeletedController extends GetxController {
  final GetTrashNotes _getTrashNotes;
  final GetFolders _getFolders;
  final DeleteRestoreNote _deleteRestoreNote;
  final DeleteRestoreFolder _deleteRestoreFolder;
  final DeleteNotePermanently _deleteNotePermanently;
  final DeleteFolderPermanently _deleteFolderPermanently;
  final EmptyTrash _emptyTrash;

  RecentlyDeletedController({
    required GetTrashNotes getTrashNotes,
    required GetFolders getFolders,
    required DeleteRestoreNote deleteRestoreNote,
    required DeleteRestoreFolder deleteRestoreFolder,
    required DeleteNotePermanently deleteNotePermanently,
    required DeleteFolderPermanently deleteFolderPermanently,
    required EmptyTrash emptyTrash,
  }) : _getTrashNotes = getTrashNotes,
       _getFolders = getFolders,
       _deleteRestoreNote = deleteRestoreNote,
       _deleteRestoreFolder = deleteRestoreFolder,
       _deleteNotePermanently = deleteNotePermanently,
       _deleteFolderPermanently = deleteFolderPermanently,
       _emptyTrash = emptyTrash;

  /// The backend has no permanent-delete or empty-trash routes, so the views
  /// hide those actions instead of offering a button that always fails.
  bool get canDeletePermanently => ApiCapabilities.permanentDelete;

  final deletedNotes = <Note>[].obs;
  final deletedFolders = <Folder>[].obs;
  final isLoading = true.obs;
  final isEditing = false.obs;
  final selectedNoteIds = <int>{}.obs;
  final selectedFolderIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDeletedItems();
  }

  @override
  void onReady() {
    super.onReady();
    fetchDeletedItems(); // Re-fetch when the user returns to the screen
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

  Future<void> fetchDeletedItems() async {
    isLoading.value = true;
    try {
      final noteResult = await _getTrashNotes(const NoParams());
      final folderResult = await _getFolders(const NoParams());

      if (noteResult case Err(:final failure)) {
        AppSnackbar.failure('Could not load deleted items', failure);
        return;
      }
      if (folderResult case Err(:final failure)) {
        AppSnackbar.failure('Could not load deleted items', failure);
        return;
      }

      deletedNotes.assignAll(noteResult.valueOrNull!);
      deletedFolders.assignAll(folderResult.valueOrNull!.trash);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recoverItem({int? noteId, int? folderId}) async {
    isLoading.value = true;
    try {
      final result = noteId != null
          ? await _deleteRestoreNote(
              DeleteRestoreNoteParams(noteId: noteId, isDelete: false),
            )
          : folderId != null
          ? await _deleteRestoreFolder(
              DeleteRestoreFolderParams(folderId: folderId, isDelete: false),
            )
          : null;

      if (result == null) return;

      switch (result) {
        case Ok():
          await fetchDeletedItems();
          AppSnackbar.success('Recovered', 'Item recovered');
        case Err(:final failure):
          AppSnackbar.failure('Could not recover item', failure);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recoverSelectedItems() async {
    final noteIds = selectedNoteIds.toList();
    final folderIds = selectedFolderIds.toList();

    // Nothing picked while in edit mode means "recover everything".
    if (noteIds.isEmpty && folderIds.isEmpty && isEditing.value) {
      await recoverAll();
      return;
    }

    await _recover(noteIds, folderIds, 'Items recovered');
  }

  Future<void> recoverAll() => _recover(
    deletedNotes.map((n) => n.id).toList(),
    deletedFolders.map((f) => f.id).toList(),
    'All items recovered',
  );

  Future<void> _recover(
    List<int> noteIds,
    List<int> folderIds,
    String successMessage,
  ) async {
    isLoading.value = true;
    try {
      for (final id in noteIds) {
        final result = await _deleteRestoreNote(
          DeleteRestoreNoteParams(noteId: id, isDelete: false),
        );
        if (result case Err(:final failure)) {
          AppSnackbar.failure('Could not recover items', failure);
          return;
        }
      }
      for (final id in folderIds) {
        final result = await _deleteRestoreFolder(
          DeleteRestoreFolderParams(folderId: id, isDelete: false),
        );
        if (result case Err(:final failure)) {
          AppSnackbar.failure('Could not recover items', failure);
          return;
        }
      }

      selectedNoteIds.clear();
      selectedFolderIds.clear();
      isEditing.value = false;
      await fetchDeletedItems();
      AppSnackbar.success('Recovered', successMessage);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteItemPermanently({
    int? noteId,
    int? folderId,
    String? name,
  }) async {
    if (!_ensureSupported()) return;

    final confirmed = await AppDialogs.confirm(
      title: noteId != null
          ? 'This note will be deleted. This action cannot be undone.'
          : 'This folder and its notes will be deleted. This action cannot be undone.',
      confirmLabel: noteId != null ? 'Delete Note' : 'Delete Folder',
    );
    if (!confirmed) return;

    isLoading.value = true;
    try {
      if (noteId != null) {
        final result = await _deleteNotePermanently(noteId);
        if (result case Err(:final failure)) {
          AppSnackbar.failure('Could not delete item', failure);
          return;
        }
        deletedNotes.removeWhere((n) => n.id == noteId);
      } else if (folderId != null) {
        final result = await _deleteFolderPermanently(folderId);
        if (result case Err(:final failure)) {
          AppSnackbar.failure('Could not delete item', failure);
          return;
        }
        deletedFolders.removeWhere((f) => f.id == folderId);
      }
      await fetchDeletedItems();
      AppSnackbar.success('Deleted', 'Item permanently deleted');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePermanentlySelectedItems() async {
    if (!_ensureSupported()) return;

    if (selectedNoteIds.isEmpty && selectedFolderIds.isEmpty) {
      if (isEditing.value) await deleteAll();
      return;
    }

    final confirmed = await AppDialogs.confirm(
      title: selectedFolderIds.isNotEmpty
          ? 'These folders and their notes will be deleted. This action cannot be undone.'
          : 'These notes will be deleted. This action cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;

    isLoading.value = true;
    try {
      for (final id in selectedNoteIds.toList()) {
        final result = await _deleteNotePermanently(id);
        if (result case Err(:final failure)) {
          AppSnackbar.failure('Could not delete items', failure);
          return;
        }
      }
      for (final id in selectedFolderIds.toList()) {
        final result = await _deleteFolderPermanently(id);
        if (result case Err(:final failure)) {
          AppSnackbar.failure('Could not delete items', failure);
          return;
        }
      }
      selectedNoteIds.clear();
      selectedFolderIds.clear();
      isEditing.value = false;
      await fetchDeletedItems();
      AppSnackbar.success('Deleted', 'Items permanently deleted');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAll() async {
    if (!_ensureSupported()) return;

    final confirmed = await AppDialogs.confirm(
      title:
          'All notes and folders in Recently Deleted will be permanently removed.',
      confirmLabel: 'Empty Trash',
    );
    if (!confirmed) return;

    isLoading.value = true;
    try {
      final result = await _emptyTrash(const NoParams());
      if (result case Err(:final failure)) {
        AppSnackbar.failure('Failed to empty trash', failure);
        return;
      }
      // `emptyTrash` only covers notes server-side — trashed folders need
      // their own permanent-delete call each, same as the per-item flows
      // above, or they'd survive "Empty Trash" indefinitely.
      for (final folder in deletedFolders.toList()) {
        final folderResult = await _deleteFolderPermanently(folder.id);
        if (folderResult case Err(:final failure)) {
          AppSnackbar.failure('Failed to empty trash', failure);
          return;
        }
      }
      isEditing.value = false;
      await fetchDeletedItems();
      AppSnackbar.success('Emptied', 'Trash emptied');
    } finally {
      isLoading.value = false;
    }
  }

  /// Guards the destructive actions the backend cannot perform yet.
  bool _ensureSupported() {
    if (canDeletePermanently) return true;
    AppSnackbar.info(
      'Not available',
      'Permanent delete is not available on the server yet.',
    );
    return false;
  }
}
