import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/search/domain/entities/search_results.dart';
import 'package:Note/features/search/domain/entities/search_user.dart';
import 'package:Note/features/search/domain/usecases/search_usecases.dart';

enum SearchScope { notes, users }

class SearchController extends GetxController {
  final SearchNotesAndFolders _search;
  final SearchUsers _searchUsers;
  final SessionStorage _session;

  SearchController({
    required SearchNotesAndFolders search,
    required SearchUsers searchUsers,
    required SessionStorage session,
  }) : _search = search,
       _searchUsers = searchUsers,
       _session = session;

  final scope = SearchScope.notes.obs;
  final userResults = <SearchUser>[].obs;
  final isLoadingUsers = false.obs;
  final userSearchError = RxnString();
  int _requestGeneration = 0;

  bool get canSearchUsers => _session.isLoggedIn;

  void changeScope(SearchScope value) {
    if (scope.value == value) return;
    _requestGeneration++;
    scope.value = value;
    clearSearch();
  }

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
    _requestGeneration++;
    _debounce?.dispose();
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String query) {
    if (searchQuery.value == query && query.trim().isNotEmpty) return;
    _requestGeneration++;
    searchQuery.value = query;
    // Matches `_run`'s blank check below — a whitespace-only query used to
    // flip `isSearching` true (showing the results view) while `_run` still
    // treated it as empty and cleared every list, landing on an empty
    // "no results" state instead of the actual empty/suggestions one.
    final isBlank = query.trim().isEmpty;
    isSearching.value = !isBlank;
    if (isBlank) {
      _clearResults();
    } else if (scope.value == SearchScope.users) {
      userResults.clear();
      userSearchError.value = null;
      isLoadingUsers.value = canSearchUsers;
    }
  }

  Future<void> _run(String query) async {
    if (isClosed) return;
    if (query.trim().isEmpty) {
      _clearResults();
      return;
    }

    final generation = ++_requestGeneration;
    if (scope.value == SearchScope.users) {
      if (!canSearchUsers) {
        isLoadingUsers.value = false;
        return;
      }
      isLoadingUsers.value = true;
      userSearchError.value = null;
      final result = await _searchUsers(query);
      if (isClosed || generation != _requestGeneration) return;
      isLoadingUsers.value = false;
      switch (result) {
        case Ok(:final value):
          userResults.assignAll(value);
        case Err(:final failure):
          userResults.clear();
          userSearchError.value = failure.message;
      }
      return;
    }

    final result = await _search(query);
    if (isClosed || generation != _requestGeneration) return;
    switch (result) {
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
    userResults.clear();
    userSearchError.value = null;
    isLoadingUsers.value = false;
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

  Future<void> retryUserSearch() => _run(searchQuery.value);
}
