import 'package:get/get.dart';
import '../../data/models/folder_model.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/models/note_model.dart';
import '../../core/utils/ui_helpers.dart';
import '../folder/folder_controller.dart';
import '../home/home_controller.dart';

class NoteListController extends GetxController {
  final NoteRepository _repository = NoteRepository();

  final notes = <NoteModel>[].obs;
  final trashFolders = <FolderModel>[].obs;
  final isLoading = false.obs;

  void fetchAllNotes() async {
    isLoading.value = true;
    try {
      final all = await _repository.getAllNotes();
      notes.value = all['note'] ?? [];
      // Sort by updatedAt descending
      notes.sort((a, b) => (b.updatedAt ?? b.createdAt ?? DateTime.now())
          .compareTo(a.updatedAt ?? a.createdAt ?? DateTime.now()));
    } finally {
      isLoading.value = false;
    }
  }

  void fetchPinnedNotes() async {
    isLoading.value = true;
    try {
      final all = await _repository.getAllNotes();
      final fetchedNotes = all['note']?.where((n) => n.isPinned).toList() ?? [];
      // Apply same sorting as Home
      notes.value = fetchedNotes
        ..sort((a, b) => (b.pinnedAt ?? b.createdAt ?? DateTime.now())
            .compareTo(a.pinnedAt ?? a.createdAt ?? DateTime.now()));
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
      
      // Also fetch trash folders
      if (Get.isRegistered<FolderController>()) {
        final folderController = Get.find<FolderController>();
        await folderController.fetchFolders();
        trashFolders.value = folderController.trashFolders;
      }
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

  Future<void> archiveNote(NoteModel note, bool isArchived) async {
    isLoading.value = true;
    try {
      await _repository.updateNoteState(
        id: note.id!, 
        isArchived: isArchived,
        isPinned: note.isPinned,
        isLocked: note.isLocked,
      );
      if (isArchived) {
        fetchPinnedNotes(); 
      } else {
        fetchArchivedNotes();
      }
      UIHelpers.showSnackBar('Success', isArchived ? 'Note archived' : 'Note restored to main list');
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to update note', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> togglePin(NoteModel note) async {
    final newState = !note.isPinned;
    try {
      await _repository.updateNoteState(
        id: note.id!, 
        isPinned: newState,
        isArchived: note.isArchived,
        isLocked: note.isLocked,
      );
      
      // Update local state immediately if in pinned list
      if (!newState) {
        notes.removeWhere((n) => n.id == note.id);
      }
      
      // Refresh Home if it exists
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchData();
      }
      
      UIHelpers.showSnackBar('Success', newState ? 'Note pinned' : 'Note unpinned');
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to update pin', isError: true);
    }
  }

  Future<void> restoreNote(int id) async {
    isLoading.value = true;
    try {
      await _repository.deleteRestoreNote(id, false);
      fetchTrashNotes();
      UIHelpers.showSnackBar('Success', 'Note restored');
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to restore note', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteNoteForever(int id) async {
    isLoading.value = true;
    try {
      await _repository.deleteRestoreNote(id, true);
      fetchTrashNotes();
      UIHelpers.showSnackBar('Success', 'Note deleted permanently');
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to delete note', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAllTrash() async {
    isLoading.value = true;
    try {
      await _repository.clearTrash();
      fetchTrashNotes();
      UIHelpers.showSnackBar('Success', 'Trash cleared');
    } catch (e) {
      UIHelpers.showSnackBar('Error', 'Failed to clear trash', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  String getDaysRemaining(DateTime? deletedAt) {
    if (deletedAt == null) return '30 days left';
    final expiryDate = deletedAt.add(const Duration(days: 30));
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? '$remaining days left' : 'Expiring soon';
  }

  String getTimeAgo(DateTime? date) {
    if (date == null) return 'recently';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays >= 1) return '${diff.inDays} days ago';
    return 'recently';
  }
}
