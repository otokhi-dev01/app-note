import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/providers/folder_service.dart';
import '../../../data/providers/note_service.dart';
import '../widgets/note_move_folder_modal.dart';

class NoteController extends GetxController {
  final _noteService = Get.find<NoteService>();

  final notes = <NoteModel>[].obs;
  final pinnedNotes = <NoteModel>[].obs;
  final otherNotes = <NoteModel>[].obs;
  final archivedNotes = <NoteModel>[].obs;
  final pinnedArchivedNotes = <NoteModel>[].obs;
  final otherArchivedNotes = <NoteModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = "".obs;

  // View and editing modes
  final isEditing = false.obs;
  final viewMode = "list".obs; // 'list' or 'gallery'
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

    isLoading.value = true;
    try {
      for (final id in targets) {
        if (kDebugMode) debugPrint("[NOTE DEBUG] Deleting NoteId: $id");
        await _noteService.deleteRestoreNote(id, true);
      }
      selectedNoteIds.clear();
      isEditing.value = false;
      await fetchNotes(folderId: folderId, refresh: true);
      Get.snackbar("Success", "Notes moved to Recently Deleted",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      if (kDebugMode) debugPrint("[NOTE DEBUG] Delete notes error: $e");
      Get.snackbar("Error", "Could not delete notes. Please check your connection.");
    } finally {
      isLoading.value = false;
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
            isLoading.value = true;
            try {
              for (final noteId in targets) {
                final note = notes.firstWhereOrNull((n) => n.id == noteId);
                if (note != null) {
                  if (kDebugMode) debugPrint("[NOTE DEBUG] Moving NoteId: $noteId to FolderId: ${folder.id}");
                  await _noteService.saveNote(
                    folder.id,
                    note.title,
                    noteId: note.id,
                    content: note.content,
                  );
                }
              }
              selectedNoteIds.clear();
              isEditing.value = false;
              await fetchNotes(folderId: currentFolderId, refresh: true);
              Get.snackbar(
                "Success",
                "Moved notes to ${folder.name}",
                snackPosition: SnackPosition.BOTTOM,
              );
            } catch (e) {
              if (kDebugMode) debugPrint("[NOTE DEBUG] Move notes error: $e");
              Get.snackbar("Error", "Failed to move notes");
            } finally {
              isLoading.value = false;
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
      final response =
          await _noteService.getNotes(folderId: folderId, refresh: refresh);
      final allNotes = _sortNotes(response.notes);
      final pinned = allNotes.where((n) => n.isPinned).toList();
      final others = allNotes.where((n) => !n.isPinned).toList();

      pinnedNotes.assignAll(pinned);
      otherNotes.assignAll(others);
      notes.assignAll([...pinned, ...others]);

      final allArchived = _sortNotes(response.archive);
      archivedNotes.assignAll(allArchived);
      pinnedArchivedNotes.assignAll(allArchived.where((n) => n.isPinned).toList());
      otherArchivedNotes.assignAll(allArchived.where((n) => !n.isPinned).toList());
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
      final dateA = a.updatedAt ?? DateTime(0);
      final dateB = b.updatedAt ?? DateTime(0);
      return dateB.compareTo(dateA);
    });
    return list;
  }

  void toggleViewMode() {
    viewMode.value = viewMode.value == "list" ? "gallery" : "list";
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



