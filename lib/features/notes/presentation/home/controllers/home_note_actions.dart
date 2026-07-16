part of '../home_controller.dart';

extension _HomeNoteActions on HomeController {
  Future<void> _togglePin(Note note) async {
    final updatedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isDeleted: note.isDeleted,
      deletedAt: note.deletedAt,
      imagePaths: note.imagePaths,
      folderId: note.folderId,
      isPinned: !note.isPinned,
      isLocked: note.isLocked,
    );
    try {
      await _updateNoteUseCase(updatedNote);
      await loadNotes();
      HapticFeedback.mediumImpact();
    } catch (error) {
      _showNoteError('Pin Update Failed', error);
    }
  }

  Future<void> _deleteNote(Note note) async {
    if (note.id == null) return;
    HapticFeedback.mediumImpact();
    final deletedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isDeleted: true,
      deletedAt: DateTime.now(),
      imagePaths: note.imagePaths,
      folderId: note.folderId,
      isPinned: note.isPinned,
      isLocked: note.isLocked,
    );
    try {
      await _updateNoteUseCase(deletedNote);
      await loadNotes();
      _showStatusSnackbar('Moved to Trash', 'Note moved to Recently Deleted.');
    } catch (error) {
      _showNoteError('Delete Failed', error);
    }
  }

  Future<void> _restoreNote(Note note) async {
    if (note.id == null) return;
    HapticFeedback.mediumImpact();
    final restoredNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      isDeleted: false,
      deletedAt: null,
      imagePaths: note.imagePaths,
      folderId: note.folderId,
      isPinned: note.isPinned,
      isLocked: note.isLocked,
    );
    try {
      await _updateNoteUseCase(restoredNote);
      await loadNotes();
      _showStatusSnackbar('Restored', 'Note restored successfully.');
    } catch (error) {
      _showNoteError('Restore Failed', error);
    }
  }

  Future<void> _restoreAllNotes() async {
    if (trashNotes.isEmpty) return;
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    try {
      for (final note in trashNotes.toList(growable: false)) {
        if (note.id == null) continue;
        await _updateNoteUseCase(
          Note(
            id: note.id,
            title: note.title,
            content: note.content,
            createdAt: note.createdAt,
            updatedAt: now,
            isDeleted: false,
            deletedAt: null,
            imagePaths: note.imagePaths,
            folderId: note.folderId,
            isPinned: note.isPinned,
            isLocked: note.isLocked,
          ),
        );
      }
      await loadNotes();
      _showStatusSnackbar('Recovered', 'All deleted notes were restored.');
    } catch (error) {
      _showNoteError('Restore Failed', error);
    }
  }

  Future<void> _permanentlyDeleteNote(Note note) async {
    if (note.id == null) return;
    HapticFeedback.heavyImpact();
    try {
      await _deleteNoteUseCase(note.id!);
      await _deleteAttachmentFiles(note.imagePaths);
      await loadNotes();
      _showStatusSnackbar(
        'Deleted',
        'Note permanently deleted.',
        isDestructive: true,
      );
    } catch (error) {
      _showNoteError('Delete Failed', error);
    }
  }

  Future<void> _clearTrash() async {
    if (trashNotes.isEmpty) return;
    Get.dialog(
      CupertinoAlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All notes in Recently Deleted will be permanently removed. This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Get.back();
              try {
                for (final note in trashNotes) {
                  if (note.id != null) {
                    await _deleteNoteUseCase(note.id!);
                    await _deleteAttachmentFiles(note.imagePaths);
                  }
                }
                await loadNotes();
                _showStatusSnackbar(
                  'Trash Emptied',
                  'All deleted notes removed.',
                  isDestructive: true,
                );
              } catch (error) {
                _showNoteError('Empty Trash Failed', error);
              }
            },
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAttachmentFiles(List<String> paths) async {
    await _attachmentFiles?.deleteAll(paths);
  }

  void _shareNote(Note note) {
    HapticFeedback.selectionClick();
    Get.bottomSheet(
      ShareBottomSheet(note: note),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  void _moveNote(Note note) {
    HapticFeedback.selectionClick();
    Get.bottomSheet(
      MoveNoteSheet(
        note: note,
        onMove: (folderId) async {
          try {
            final updatedNote = note.copyWith(
              folderId: folderId,
              updatedAt: DateTime.now(),
            );
            await _updateNoteUseCase(updatedNote);
            await loadNotes();
            _showStatusSnackbar('Moved', 'Note moved successfully.');
          } catch (error) {
            _showNoteError('Move Failed', error);
          }
        },
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  void _openRecentlyDeleted() {
    if (isEditing.value) return;
    HapticFeedback.selectionClick();
    showTrash();
  }
}
