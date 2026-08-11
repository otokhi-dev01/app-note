import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/providers/folder_service.dart';
import '../../../data/providers/note_service.dart';

class SearchController extends GetxController {
  final _noteService = Get.find<NoteService>();
  final _folderService = Get.find<FolderService>();

  final noteResults = <NoteModel>[].obs;
  final pinnedNoteResults = <NoteModel>[].obs;
  final otherNoteResults = <NoteModel>[].obs;
  final folderResults = <FolderModel>[].obs;

  final searchQuery = "".obs;
  final isSearching = false.obs;
  final searchController = TextEditingController();

  final suggestions = [
    {"title": "Shared Notes", "icon": CupertinoIcons.person_crop_circle},
    {"title": "Locked Notes", "icon": CupertinoIcons.lock},
    {
      "title": "Notes with Checklists",
      "icon": CupertinoIcons.list_bullet_indent,
    },
    {"title": "Notes with Tags", "icon": CupertinoIcons.number},
    {"title": "Notes with Drawings", "icon": CupertinoIcons.pencil_outline},
    {
      "title": "Notes with Scanned Documents",
      "icon": CupertinoIcons.doc_text_viewfinder,
    },
    {"title": "Notes with Attachments", "icon": CupertinoIcons.paperclip},
  ];

  void onSearchChanged(String query) {
    searchQuery.value = query;
    isSearching.value = query.isNotEmpty;
    search(query);
  }

  void search(String query) async {
    if (query.isEmpty) {
      noteResults.clear();
      folderResults.clear();
      return;
    }

    try {
      // Fetch both notes and folders
      final results = await Future.wait([
        _noteService.getNotes(refresh: true),
        _folderService.getFolders(),
      ]);

      final noteResponse = results[0] as NoteResponse;
      final List<NoteModel> allNotes = noteResponse.notes;
      final folderResponse = results[1] as FolderResponse;
      final List<FolderModel> allFolders = folderResponse.folders;

      final lowerQuery = query.toLowerCase();
      List<NoteModel> filteredNotes = [];

      // Check if query matches a suggested filter
      if (lowerQuery == "shared notes") {
        filteredNotes = allNotes
            .where((n) => n.folderName.toLowerCase().contains("shared"))
            .toList();
        folderResults.clear();
      } else if (lowerQuery == "locked notes") {
        filteredNotes = allNotes.where((n) => n.isLocked).toList();
        folderResults.clear();
      } else if (lowerQuery == "notes with checklists") {
        filteredNotes = allNotes
            .where((n) => n.content.any((b) => b is ChecklistBlock))
            .toList();
        folderResults.clear();
      } else if (lowerQuery == "notes with tags") {
        filteredNotes = allNotes.where((n) => n.title.contains("#")).toList();
        folderResults.clear();
      } else if (lowerQuery == "notes with drawings") {
        filteredNotes = allNotes
            .where((n) => n.content.any((b) => b is DrawingBlock))
            .toList();
        folderResults.clear();
      } else if (lowerQuery == "notes with scanned documents") {
        filteredNotes = allNotes.where((n) => n.attachmentCount > 0).toList();
        folderResults.clear();
      } else if (lowerQuery == "notes with attachments") {
        filteredNotes = allNotes
            .where(
              (n) =>
                  n.attachmentCount > 0 ||
                  n.content.any((b) => b is AttachmentBlock),
            )
            .toList();
        folderResults.clear();
      } else {
        // Regular search
        filteredNotes = allNotes
            .where(
              (n) =>
                  n.title.toLowerCase().contains(lowerQuery) ||
                  n.folderName.toLowerCase().contains(lowerQuery),
            )
            .toList();

        folderResults.assignAll(
          allFolders
              .where((f) => f.name.toLowerCase().contains(lowerQuery))
              .toList(),
        );
      }

      noteResults.assignAll(filteredNotes);
      pinnedNoteResults.assignAll(
        filteredNotes.where((n) => n.isPinned).toList(),
      );
      otherNoteResults.assignAll(
        filteredNotes.where((n) => !n.isPinned).toList(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint("SEARCH ERROR: $e");
    }
  }

  void applyFilter(String filter) {
    searchController.text = filter;
    onSearchChanged(filter);
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged("");
  }
}
