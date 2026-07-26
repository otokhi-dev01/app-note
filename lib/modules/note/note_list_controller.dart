import 'package:get/get.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/models/note_model.dart';

class NoteListController extends GetxController {
  final NoteRepository _repository = NoteRepository();

  final notes = <NoteModel>[].obs;
  final isLoading = false.obs;

  void fetchPinnedNotes() async {
    isLoading.value = true;
    try {
      final all = await _repository.getAllNotes();
      notes.value = all['note']?.where((n) => n.isPinned).toList() ?? [];
    } finally {
      isLoading.value = false;
    }
  }

  void fetchArchivedNotes() async {
    isLoading.value = true;
    try {
      final all = await _repository.getAllNotes();
      notes.value = all['archive'] ?? [];
    } finally {
      isLoading.value = false;
    }
  }

  void fetchTrashNotes() async {
    isLoading.value = true;
    try {
      final all = await _repository.getAllNotes();
      notes.value = all['trash'] ?? [];
    } finally {
      isLoading.value = false;
    }
  }

  void fetchLockedNotes() async {
    isLoading.value = true;
    try {
      final all = await _repository.getAllNotes();
      notes.value = all['note']?.where((n) => n.isLocked).toList() ?? [];
    } finally {
      isLoading.value = false;
    }
  }

  void searchNotes(String query) async {
    if (query.isEmpty) {
      notes.clear();
      return;
    }
    isLoading.value = true;
    try {
      final all = await _repository.getAllNotes();
      notes.value = all['note']?.where((n) => 
        n.title.toLowerCase().contains(query.toLowerCase())
      ).toList() ?? [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> archiveNote(int id, bool isArchived) async {
    isLoading.value = true;
    try {
      await _repository.updateNoteState(id: id, isArchived: isArchived);
      fetchArchivedNotes();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restoreNote(int id) async {
    isLoading.value = true;
    try {
      await _repository.deleteRestoreNote(id, false);
      fetchTrashNotes();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteNoteForever(int id) async {
    isLoading.value = true;
    try {
      await _repository.deleteRestoreNote(id, true);
      fetchTrashNotes();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAllTrash() async {
    isLoading.value = true;
    try {
      await _repository.clearTrash();
      fetchTrashNotes();
    } finally {
      isLoading.value = false;
    }
  }
}
