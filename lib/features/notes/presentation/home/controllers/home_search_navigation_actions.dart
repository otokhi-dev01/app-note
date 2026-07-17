part of '../home_controller.dart';

extension _HomeSearchNavigationActions on HomeController {
  Future<void> _loadRecentSearches() async {
    final list = await _recentSearchRepository.load(
      accountScopeId: _authRepository?.accountScopeId,
    );
    recentSearches.assignAll(list);
  }

  Future<void> _saveRecentSearches() async {
    await _recentSearchRepository.save(
      recentSearches.toList(growable: false),
      accountScopeId: _authRepository?.accountScopeId,
    );
  }

  void _addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    final trimmedQuery = query.trim();
    recentSearches.remove(trimmedQuery);
    recentSearches.insert(0, trimmedQuery);
    if (recentSearches.length > 10) {
      recentSearches.removeLast();
    }
    _saveRecentSearches();
  }

  void _clearRecentSearches() {
    recentSearches.clear();
    _saveRecentSearches();
  }

  void _removeRecentSearch(String query) {
    recentSearches.remove(query);
    _saveRecentSearches();
  }

  void _applyFilter() {
    final baseNotes = selectedFolder.value == null
        ? notes
        : notes.where((note) => note.folderId == selectedFolder.value!.id);
    pinnedNotes.assignAll(baseNotes.where((note) => note.isPinned).toList());
    filteredNotes.assignAll(baseNotes.where((note) => !note.isPinned).toList());
  }

  void _toggleViewMode() {
    isGalleryView.value = !isGalleryView.value;
    HapticFeedback.selectionClick();
  }

  void _selectFolder(Folder? folder) {
    if (isEditing.value) return;
    selectedFolder.value = folder;
    isFolderView.value = false;
    isSearching.value = false;
    isTrashView.value = false;
    selectedTab.value = 0;
    _applyFilter();
  }

  void _selectTab(int index) {
    if (index < 0 || index > 3) return;
    HapticFeedback.selectionClick();
    selectedTab.value = index;
    isTrashView.value = false;
    isEditing.value = false;

    if (index == 0) {
      isFolderView.value = false;
      isSearching.value = false;
      selectedFolder.value = null;
      _applyFilter();
    } else if (index == 1) {
      isFolderView.value = true;
      isSearching.value = false;
    } else if (index == 2) {
      isFolderView.value = false;
      isSearching.value = true;
      if (searchQuery.value.isEmpty && activeSearchToken.value == null) {
        filteredNotes.assignAll(notes);
      }
    } else {
      isFolderView.value = false;
      isSearching.value = false;
    }
  }

  void _toggleEdit() {
    isEditing.value = !isEditing.value;
  }

  void _toggleNotesSection() {
    isNotesSectionExpanded.value = !isNotesSectionExpanded.value;
  }

  void _toggleLocalSection() {
    isLocalSectionExpanded.value = !isLocalSectionExpanded.value;
  }

  void _toggleTagsSection() {
    isTagsSectionExpanded.value = !isTagsSectionExpanded.value;
  }

  void _showFolders() {
    isFolderView.value = true;
    isSearching.value = false;
    isEditing.value = false;
    isTrashView.value = false;
    selectedTab.value = 1;
  }

  void _showTrash() {
    isTrashView.value = true;
    isFolderView.value = false;
    isSearching.value = false;
    isEditing.value = false;
    selectedTab.value = 1;
  }

  void _startSearch() {
    isSearching.value = true;
    selectedTab.value = 2;
    filteredNotes.assignAll(notes);
  }

  void _cancelSearch() {
    isSearching.value = false;
    searchQuery.value = '';
    activeSearchToken.value = null;
    searchFieldController.clear();
    _applyFilter();
  }

  void _search(String query) {
    searchQuery.value = query;
    if (searchFieldController.text != query) {
      searchFieldController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    final keyword = query.trim().toLowerCase();
    final results = _noteSearchService.matchingText(notes, query);
    filteredNotes.assignAll(results);
    if (keyword.isNotEmpty && results.isNotEmpty && keyword.length > 2) {
      addRecentSearch(query);
    }
  }

  void _searchByFilter(String type) {
    isSearching.value = true;
    selectedTab.value = 2;
    switch (type) {
      case 'attachments':
        filteredNotes.assignAll(_noteSearchService.matchingFilter(notes, type));
        activeSearchToken.value = 'Attachments';
        break;
      case 'shared':
        _showStatusSnackbar(
          'Shared Notes',
          'Sharing features are coming soon!',
        );
        filteredNotes.assignAll(_noteSearchService.matchingFilter(notes, type));
        activeSearchToken.value = 'Shared';
        break;
      case 'drawings':
        filteredNotes.assignAll(_noteSearchService.matchingFilter(notes, type));
        activeSearchToken.value = 'Drawings';
        break;
      case 'checklists':
        filteredNotes.assignAll(_noteSearchService.matchingFilter(notes, type));
        activeSearchToken.value = 'Checklists';
        break;
      case 'tags':
        filteredNotes.assignAll(_noteSearchService.matchingFilter(notes, type));
        activeSearchToken.value = 'Tags';
        break;
      case 'locked':
        filteredNotes.assignAll(_noteSearchService.matchingFilter(notes, type));
        activeSearchToken.value = 'Locked';
        break;
      case 'scanned':
        _showStatusSnackbar(
          'Scanned Documents',
          'Document scanning is not available.',
        );
        filteredNotes.assignAll(_noteSearchService.matchingFilter(notes, type));
        activeSearchToken.value = 'Scanned';
        break;
    }
  }

  void _searchCategory(String category) {
    activeSearchToken.value = category;
    selectedTab.value = 2;
    isSearching.value = true;
    filteredNotes.assignAll(
      _noteSearchService.matchingCategory(notes, category),
    );
  }

  void _removeSearchToken() {
    activeSearchToken.value = null;
    search(searchQuery.value);
  }

  Future<void> _openCreateNote() async {
    HapticFeedback.lightImpact();
    final result = await Get.toNamed(
      AppRoutes.editor,
      arguments: selectedFolder.value?.id,
    );
    if (result != EditorResult.saved) return;

    await loadNotes();
    isFolderView.value = false;
    isSearching.value = false;
    isTrashView.value = false;
    selectedTab.value = 0;
    _applyFilter();
  }

  Future<void> _openNote(Note note) async {
    HapticFeedback.selectionClick();
    await Get.toNamed(AppRoutes.detail, arguments: note.id);
    await loadNotes();
  }

  void _goToSettings() {
    HapticFeedback.lightImpact();
    Get.toNamed(AppRoutes.settings);
  }
}

final class _TransientRecentSearchRepository implements RecentSearchRepository {
  const _TransientRecentSearchRepository();

  @override
  Future<List<String>> load({required String? accountScopeId}) async {
    return const [];
  }

  @override
  Future<void> save(
    List<String> searches, {
    required String? accountScopeId,
  }) async {}
}
