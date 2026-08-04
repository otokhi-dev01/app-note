import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/note_model.dart';
import '../../data/models/folder_model.dart';
import '../../data/services/note_service.dart';
import '../../data/services/folder_service.dart';

class SearchController extends GetxController {
  final _noteService = Get.find<NoteService>();
  final _folderService = Get.find<FolderService>();
  
  final noteResults = <NoteModel>[].obs;
  final folderResults = <FolderModel>[].obs;
  
  final searchQuery = "".obs;
  final isSearching = false.obs;
  final searchController = TextEditingController();

  final suggestions = [
    {"title": "Shared Notes", "icon": Icons.account_circle_outlined},
    {"title": "Locked Notes", "icon": Icons.lock_outline},
    {"title": "Notes with Checklists", "icon": Icons.checklist_rtl_rounded},
    {"title": "Notes with Tags", "icon": Icons.tag_rounded},
    {"title": "Notes with Drawings", "icon": Icons.draw_outlined},
    {"title": "Notes with Scanned Documents", "icon": Icons.document_scanner_outlined},
    {"title": "Notes with Attachments", "icon": Icons.attach_file_rounded},
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
        _noteService.getNotes(),
        _folderService.getFolders(),
      ]);

      final noteResponse = results[0] as NoteResponse;
      final List<NoteModel> allNotes = noteResponse.notes;
      final folderResponse = results[1] as FolderResponse;
      final List<FolderModel> allFolders = folderResponse.folders;

      // Filter notes
      noteResults.assignAll(allNotes.where((n) => 
        n.title.toLowerCase().contains(query.toLowerCase())
      ).toList());

      // Filter folders
      folderResults.assignAll(allFolders.where((f) => 
        f.name.toLowerCase().contains(query.toLowerCase())
      ).toList());
      
    } catch (e) {
      // Handle error
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
