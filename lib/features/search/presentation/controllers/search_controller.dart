import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/search/domain/entities/search_results.dart';
import 'package:Note/features/search/domain/usecases/search_usecases.dart';

class SearchController extends GetxController {
  final SearchNotesAndFolders _search;

  SearchController({required SearchNotesAndFolders search}) : _search = search;

  final noteResults = <Note>[].obs;
  final pinnedNoteResults = <Note>[].obs;
  final otherNoteResults = <Note>[].obs;
  final folderResults = <Folder>[].obs;

  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final searchController = TextEditingController();

  /// Icons pair with [SearchFilter], which owns the labels and match rules.
  static const Map<SearchFilter, IconData> _filterIcons = {
    SearchFilter.shared: CupertinoIcons.person_crop_circle,
    SearchFilter.locked: CupertinoIcons.lock,
    SearchFilter.checklists: CupertinoIcons.list_bullet_indent,
    SearchFilter.tags: CupertinoIcons.number,
    SearchFilter.drawings: CupertinoIcons.pencil_outline,
    SearchFilter.scanned: CupertinoIcons.doc_text_viewfinder,
    SearchFilter.attachments: CupertinoIcons.paperclip,
  };

  List<Map<String, dynamic>> get suggestions => [
    for (final entry in _filterIcons.entries)
      {'title': entry.key.label, 'icon': entry.value},
  ];

  /// Debounces so a fast typist does not fire a request per keystroke.
  Worker? _debounce;

  @override
  void onInit() {
    super.onInit();
    _debounce = debounce(
      searchQuery,
      _run,
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    _debounce?.dispose();
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    // Matches `_run`'s blank check below — a whitespace-only query used to
    // flip `isSearching` true (showing the results view) while `_run` still
    // treated it as empty and cleared every list, landing on an empty
    // "no results" state instead of the actual empty/suggestions one.
    final isBlank = query.trim().isEmpty;
    isSearching.value = !isBlank;
    if (isBlank) _clearResults();
  }

  Future<void> _run(String query) async {
    if (query.trim().isEmpty) {
      _clearResults();
      return;
    }

    switch (await _search(query)) {
      case Ok(:final value):
        noteResults.assignAll(value.notes);
        pinnedNoteResults.assignAll(value.pinnedNotes);
        otherNoteResults.assignAll(value.otherNotes);
        folderResults.assignAll(value.folders);
      case Err(:final failure):
        AppSnackbar.failure('Search failed', failure);
    }
  }

  void _clearResults() {
    noteResults.clear();
    pinnedNoteResults.clear();
    otherNoteResults.clear();
    folderResults.clear();
  }

  void applyFilter(String filter) {
    searchController.text = filter;
    onSearchChanged(filter);
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }
}
