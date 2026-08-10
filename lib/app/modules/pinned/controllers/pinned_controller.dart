import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/models/note_model.dart';
import '../../../data/providers/note_service.dart';

class PinnedController extends GetxController {
  final _noteService = Get.find<NoteService>();

  final pinnedNotes = <NoteModel>[].obs;
  final isLoading = true.obs;
  final isEditing = false.obs;
  final selectedNoteIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPinnedNotes();
  }

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

  Future<void> fetchPinnedNotes() async {
    isLoading.value = true;
    try {
      final response = await _noteService.getNotes(refresh: true);
      pinnedNotes.assignAll(response.notes.where((n) => n.isPinned).toList());
      
      // Sort by updatedAt descending
      pinnedNotes.sort((a, b) {
        if (a.updatedAt == null) return 1;
        if (b.updatedAt == null) return -1;
        return b.updatedAt!.compareTo(a.updatedAt!);
      });
    } catch (e) {
      if (kDebugMode) debugPrint("[PINNED DEBUG] fetchPinnedNotes ERROR: $e");
      Get.snackbar("Error", "Could not load pinned notes");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> unpinNote(int id) async {
    try {
      await _noteService.updateNoteState(id, isPinned: false);
      pinnedNotes.removeWhere((n) => n.id == id);
      Get.snackbar("Success", "Note unpinned", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Could not unpin note");
    }
  }

  Future<void> unpinSelectedNotes() async {
    if (selectedNoteIds.isEmpty) return;
    
    try {
      for (final id in selectedNoteIds) {
        await _noteService.updateNoteState(id, isPinned: false);
      }
      fetchPinnedNotes();
      toggleEditing();
      Get.snackbar("Success", "Selected notes unpinned", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Could not unpin some notes");
    }
  }
}
