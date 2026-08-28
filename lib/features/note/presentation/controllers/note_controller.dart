import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/display_preferences.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_create_modal.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';
import 'package:Note/features/note/presentation/widgets/note_move_folder_modal.dart';

/// Drives the note list, the archive, and the multi-select bar on both.
class NoteController extends GetxController {
  final GetNotes _getNotes;
  final UpdateNoteState _updateNoteState;
  final DeleteRestoreNote _deleteRestoreNote;
  final MoveNotesToFolder _moveNotes;
  final GetFolders _getFolders;
  final CreateAudioNote _createAudioNote;

  NoteController({
    required GetNotes getNotes,
    required UpdateNoteState updateNoteState,
    required DeleteRestoreNote deleteRestoreNote,
    required MoveNotesToFolder moveNotes,
    required GetFolders getFolders,
    required CreateAudioNote createAudioNote,
  }) : _getNotes = getNotes,
       _updateNoteState = updateNoteState,
       _deleteRestoreNote = deleteRestoreNote,
       _moveNotes = moveNotes,
       _getFolders = getFolders,
       _createAudioNote = createAudioNote;

  final _prefs = DisplayPreferences();

  final notes = <Note>[].obs;
  final pinnedNotes = <Note>[].obs;
  final otherNotes = <Note>[].obs;
  final archivedNotes = <Note>[].obs;
  final pinnedArchivedNotes = <Note>[].obs;
  final otherArchivedNotes = <Note>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // View and editing modes
  final isEditing = false.obs;
  late final viewMode = _prefs.noteViewMode.obs; // 'list' or 'gallery'
  final isGroupedByDate = true.obs;
  late final sortByName = _prefs.noteSortByName.obs;
  final selectedNoteIds = <int>{}.obs;

  bool isSelected(int id) => selectedNoteIds.contains(id);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    fetchNotes(folderId: args is Folder ? args.id : null);
  }

  void toggleEditing() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) selectedNoteIds.clear();
  }

  void toggleSelectNote(int id) {
    if (selectedNoteIds.contains(id)) {
      selectedNoteIds.remove(id);
    } else {
      selectedNoteIds.add(id);
    }
    selectedNoteIds.refresh();
  }

  /// Narrows the selection to a single note — used by the per-tile context
  /// menu, which acts on one note while reusing the batch operations.
  void selectOnly(int id) {
    selectedNoteIds.assignAll({id});
  }

  Future<void> fetchNotes({int? folderId, bool refresh = false}) async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final result = await _getNotes(GetNotesParams(folderId: folderId));

      switch (result) {
        case Ok(:final value):
          final active = _sorted(value.notes);
          final pinned = active.where((n) => n.isPinned).toList();
          final others = active.where((n) => !n.isPinned).toList();

          pinnedNotes.assignAll(pinned);
          otherNotes.assignAll(others);
          notes.assignAll([...pinned, ...others]);

          final archived = _sorted(value.archive);
          archivedNotes.assignAll(archived);
          pinnedArchivedNotes.assignAll(archived.where((n) => n.isPinned));
          otherArchivedNotes.assignAll(archived.where((n) => !n.isPinned));

        case Err(:final failure):
          hasError.value = true;
          errorMessage.value = failure.message;
          AppSnackbar.failure('Could not load notes', failure);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveRecordedAudio({
    required int folderId,
    required String filePath,
    required String displayName,
  }) async {
    final targetFolderId = await _resolveRecordingFolderId(folderId);
    if (targetFolderId == null) return;

    final result = await _createAudioNote(
      CreateAudioNoteParams(
        folderId: targetFolderId,
        title: 'note_editor_recording_fallback_name'.tr,
        filePath: filePath,
        displayName: displayName,
        blockId: 'audio_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    switch (result) {
      case Ok():
        await fetchNotes(
          folderId: folderId <= 0 ? null : folderId,
          refresh: true,
        );
        _refreshFolderCounts();
        AppSnackbar.success(
          'note_editor_recording_fallback_name'.tr,
          'note_editor_voice_note_saved'.tr,
        );
      case Err(:final failure):
        AppSnackbar.failure('note_editor_could_not_save_recording'.tr, failure);
    }
  }

  Future<int?> _resolveRecordingFolderId(int folderId) async {
    if (folderId > 0) return folderId;

    final result = await _getFolders(const NoParams());
    if (result case Err(:final failure)) {
      AppSnackbar.failure('Could not load folders', failure);
      return null;
    }
    final folders = result.valueOrNull!.folders;
    if (folders.isEmpty) {
      AppSnackbar.info(
        'No folders yet',
        'Please create a folder before recording a voice note.',
      );
      return null;
    }
    return folders
        .firstWhere(
          (folder) => folder.name.toLowerCase().contains('notes'),
          orElse: () => folders.first,
        )
        .id;
  }

  Future<void> updateNoteState(
    int id, {
    bool? isPinned,
    bool? isArchived,
  }) async {
    final result = await _updateNoteState(
      UpdateNoteStateParams(
        noteId: id,
        isPinned: isPinned,
        isArchived: isArchived,
      ),
    );

    if (result case Err(:final failure)) {
      AppSnackbar.failure('Failed to update note', failure);
      return;
    }

    _applyNoteStateLocally(id, isPinned: isPinned, isArchived: isArchived);
  }

  /// Optimistic local update so the row reacts before the next fetch. A note
  /// can jump partitions here — pin toggles pinned/other, archive toggles
  /// active/archived — so every list the UI actually renders from
  /// ([pinnedNotes]/[otherNotes]/[pinnedArchivedNotes]/[otherArchivedNotes]),
  /// not just [notes], has to move with it, re-sorted the same way
  /// [fetchNotes] does.
  void _applyNoteStateLocally(int id, {bool? isPinned, bool? isArchived}) {
    Note? old;
    for (final n in [...notes, ...archivedNotes]) {
      if (n.id == id) {
        old = n;
        break;
      }
    }
    if (old == null) return;

    final updated = Note(
      id: old.id,
      folderId: old.folderId,
      folderName: old.folderName,
      title: old.title,
      content: old.content,
      isPinned: isPinned ?? old.isPinned,
      isArchived: isArchived ?? old.isArchived,
      isLocked: old.isLocked,
      updatedAt: DateTime.now(),
      deletedAt: old.deletedAt,
      attachmentCount: old.attachmentCount,
    );

    notes.removeWhere((n) => n.id == id);
    archivedNotes.removeWhere((n) => n.id == id);
    (updated.isArchived ? archivedNotes : notes).add(updated);

    final activeSorted = _sorted(notes);
    notes.assignAll(activeSorted);
    pinnedNotes.assignAll(activeSorted.where((n) => n.isPinned));
    otherNotes.assignAll(activeSorted.where((n) => !n.isPinned));

    final archivedSorted = _sorted(archivedNotes);
    archivedNotes.assignAll(archivedSorted);
    pinnedArchivedNotes.assignAll(archivedSorted.where((n) => n.isPinned));
    otherArchivedNotes.assignAll(archivedSorted.where((n) => !n.isPinned));
  }

  Future<void> deleteSelectedNotes(int folderId) async {
    final targets = selectedNoteIds.isNotEmpty
        ? selectedNoteIds.toList()
        : notes.map((n) => n.id).toList();
    if (targets.isEmpty) return;

    isLoading.value = true;
    try {
      var deleted = 0;
      for (final id in targets) {
        final result = await _deleteRestoreNote(
          DeleteRestoreNoteParams(noteId: id, isDelete: true),
        );
        if (result case Err(:final failure)) {
          AppSnackbar.failure('Could not delete notes', failure);
          break;
        }
        deleted++;
        // Optimistic removal keeps the list from flashing the deleted row.
        notes.removeWhere((n) => n.id == id);
        pinnedNotes.removeWhere((n) => n.id == id);
        otherNotes.removeWhere((n) => n.id == id);
      }

      selectedNoteIds.clear();
      isEditing.value = false;

      await fetchNotes(
        folderId: folderId == 0 ? null : folderId,
        refresh: true,
      );
      _refreshFolderCounts();

      if (deleted > 0) {
        AppSnackbar.success(
          'Moved to Trash',
          '$deleted note${deleted == 1 ? '' : 's'} moved to Recently Deleted',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> moveSelectedNotes(
    BuildContext context,
    int currentFolderId,
  ) async {
    final targetIds = selectedNoteIds.isNotEmpty
        ? selectedNoteIds.toList()
        : notes.map((n) => n.id).toList();
    if (targetIds.isEmpty) return;
    if (!context.mounted) return;
    await _openFolderPicker(context, targetIds, currentFolderId);
  }

  Future<void> _openFolderPicker(
    BuildContext context,
    List<int> targetIds,
    int currentFolderId,
  ) async {
    final folderResult = await _getFolders(const NoParams());
    if (folderResult case Err(:final failure)) {
      AppSnackbar.failure('Could not fetch folders', failure);
      return;
    }

    final allFolders = folderResult.valueOrNull!.folders;
    if (allFolders.isEmpty) {
      AppSnackbar.info('Nowhere to move', 'No destination folders available.');
      return;
    }

    if (!context.mounted) return;

    await Get.to(
      () => NoteMoveFolderModal(
        folders: allFolders,
        currentFolderId: currentFolderId,
        onFolderSelected: (folder) async {
          Get.back();
          await _moveNotesTo(folder, targetIds, currentFolderId);
        },
        onCreateNewFolder: () async {
          // Waits for FolderCreateModal to pop back here (rather than all
          // the way out to the main Folder screen), then reopens the picker
          // so the folder just created shows up as a destination.
          await Get.to(
            () => FolderCreateModal(
              controller: Get.find<FolderController>(),
              onDone: () => Get.back(),
            ),
            fullscreenDialog: true,
            transition: Transition.cupertino,
          );
          Get.back(); // Close the now-stale picker
          if (!context.mounted) return;
          await _openFolderPicker(context, targetIds, currentFolderId);
        },
      ),
      fullscreenDialog: true,
      transition: Transition.cupertino,
    );
  }

  Future<void> _moveNotesTo(
    Folder folder,
    List<int> noteIds,
    int currentFolderId,
  ) async {
    isLoading.value = true;
    try {
      final selected = notes.where((n) => noteIds.contains(n.id)).toList();
      final result = await _moveNotes(
        MoveNotesParams(notes: selected, targetFolderId: folder.id),
      );

      switch (result) {
        case Ok(:final value):
          selectedNoteIds.clear();
          isEditing.value = false;
          await fetchNotes(folderId: currentFolderId, refresh: true);
          _refreshFolderCounts();
          if (value.isComplete) {
            AppSnackbar.success(
              'Moved',
              'Moved notes to ${folder.displayName}',
            );
          } else {
            AppSnackbar.warning(
              'Partially moved',
              '${value.moved} of ${value.total} notes moved to ${folder.displayName}.',
            );
          }
        case Err(:final failure):
          AppSnackbar.failure('Failed to move notes', failure);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Folder badges show note counts, so they go stale after a move or delete.
  void _refreshFolderCounts() {
    if (Get.isRegistered<FolderController>()) {
      Get.find<FolderController>().fetchFolders(refresh: true);
    }
  }

  List<Note> _sorted(List<Note> list) {
    final copy = List<Note>.from(list);
    if (sortByName.value) {
      copy.sort(
        (a, b) => a.displayTitle.toLowerCase().compareTo(
          b.displayTitle.toLowerCase(),
        ),
      );
    } else {
      copy.sort((a, b) {
        final dateA = a.updatedAt ?? DateTime(0);
        final dateB = b.updatedAt ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
    }
    return copy;
  }

  /// Re-sorts the already-loaded lists in place, without a network round
  /// trip — used when the sort preference changes mid-session.
  void _resortLoaded() {
    final active = _sorted([...pinnedNotes, ...otherNotes]);
    pinnedNotes.assignAll(active.where((n) => n.isPinned));
    otherNotes.assignAll(active.where((n) => !n.isPinned));
    notes.assignAll(active);

    final archived = _sorted(archivedNotes);
    pinnedArchivedNotes.assignAll(archived.where((n) => n.isPinned));
    otherArchivedNotes.assignAll(archived.where((n) => !n.isPinned));
    archivedNotes.assignAll(archived);
  }

  void applyViewMode(String mode) {
    if (viewMode.value == mode) return;
    viewMode.value = mode;
    _prefs.setNoteViewMode(mode);
  }

  void toggleViewMode() =>
      applyViewMode(viewMode.value == 'list' ? 'gallery' : 'list');

  void applySortByName(bool value) {
    if (sortByName.value == value) return;
    sortByName.value = value;
    _prefs.setNoteSortByName(value);
    _resortLoaded();
  }

  void toggleSortByName() => applySortByName(!sortByName.value);

  void toggleDateGrouping() {
    isGroupedByDate.value = !isGroupedByDate.value;
    AppSnackbar.info(
      'Grouping',
      isGroupedByDate.value ? 'Grouped by date' : 'Ungrouped',
    );
  }

  void viewAllAttachments() =>
      AppSnackbar.info('Attachments', 'Viewing all attachments');
}
