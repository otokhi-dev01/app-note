import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/note_model.dart';
import '../../data/models/folder_model.dart';
import '../../data/services/folder_service.dart';
import '../../data/services/note_service.dart';
import 'widgets/note_move_folder_modal.dart';

class NoteController extends GetxController {
  final _noteService = Get.find<NoteService>();

  final notes = <NoteModel>[].obs;
  final archivedNotes = <NoteModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = "".obs;

  // Edit and selection mode for list view
  final isEditing = false.obs;
  final selectedNoteIds = <int>{}.obs;
  
  void toggleEditing() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      selectedNoteIds.clear();
    }
  }

  void toggleSelectNote(int id) {
    if (selectedNoteIds.contains(id)) {
      selectedNoteIds.remove(id);
    } else {
      selectedNoteIds.add(id);
    }
  }

  Future<void> deleteSelectedNotes(int folderId) async {
    final targets = selectedNoteIds.isNotEmpty
        ? selectedNoteIds.toList()
        : notes.map((n) => n.id).toList();

    if (targets.isEmpty) return;

    try {
      for (final id in targets) {
        await _noteService.deleteRestoreNote(id, true);
      }
      selectedNoteIds.clear();
      isEditing.value = false;
      await fetchNotes(folderId: folderId);
      Get.snackbar("Success", "Notes moved to Recently Deleted",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Could not delete notes");
    }
  }

  Future<void> moveSelectedNotes(BuildContext context, int currentFolderId) async {
    final targets = selectedNoteIds.isNotEmpty
        ? selectedNoteIds.toList()
        : notes.map((n) => n.id).toList();

    if (targets.isEmpty) return;

    try {
      final folderRes = await Get.find<FolderService>().getFolders();
      final allFolders = folderRes.folders;

      if (allFolders.isEmpty) {
        Get.snackbar("Info", "No destination folders available");
        return;
      }

      Get.bottomSheet(
        NoteMoveFolderModal(
          folders: allFolders,
          currentFolderId: currentFolderId,
          onFolderSelected: (folder) async {
            Get.back();
            try {
              for (final noteId in targets) {
                final note = notes.firstWhereOrNull((n) => n.id == noteId);
                if (note != null) {
                  await _noteService.saveNote(
                    folder.id,
                    note.title,
                    noteId: note.id,
                  );
                }
              }
              selectedNoteIds.clear();
              isEditing.value = false;
              await fetchNotes(folderId: currentFolderId);
              Get.snackbar(
                "Success",
                "Moved notes to ${folder.name}",
                snackPosition: SnackPosition.BOTTOM,
              );
            } catch (e) {
              Get.snackbar("Error", "Failed to move notes");
            }
          },
        ),
        isScrollControlled: true,
      );
    } catch (e) {
      Get.snackbar("Error", "Could not fetch folders");
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is FolderModel) {
      fetchNotes(folderId: args.id);
    } else {
      fetchNotes();
    }
  }

  Future<void> fetchNotes({int? folderId, bool refresh = false}) async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final response = await _noteService.getNotes(folderId: folderId, refresh: refresh);
      notes.assignAll(_sortNotes(response.notes));
      archivedNotes.assignAll(_sortNotes(response.archive));
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "Unable to load notes. Please check your connection.";
      Get.snackbar("Error", "Could not load notes");
    } finally {
      isLoading.value = false;
    }
  }

  List<NoteModel> _sortNotes(List<NoteModel> list) {
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final dateA = a.updatedAt ?? DateTime(0);
      final dateB = b.updatedAt ?? DateTime(0);
      return dateB.compareTo(dateA);
    });
    return list;
  }

  void toggleViewMode() {
    Get.snackbar("Info", "Gallery View coming soon");
  }

  void updateSorting(String criteria) {
    Get.snackbar("Info", "Sorting by $criteria");
  }

  void toggleDateGrouping() {
    Get.snackbar("Info", "Date grouping toggled");
  }

  void viewAllAttachments() {
    Get.snackbar("Info", "Viewing all attachments");
  }
}



