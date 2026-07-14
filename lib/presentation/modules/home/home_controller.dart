import 'package:notes/presentation/modules/home/widgets/create_folder_view.dart';
import 'package:notes/presentation/modules/home/widgets/home_sheets.dart';
import 'package:notes/data/models/note_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notes/domain/usecases/delete_note_usecase.dart';
import 'package:notes/domain/repositories/note_repository.dart';
import 'package:notes/domain/usecases/get_notes_usecase.dart';
import 'package:notes/domain/usecases/update_note_usecase.dart';
import 'package:notes/domain/entities/folder.dart';
import 'package:notes/app/routes/app_routes.dart';
import 'package:notes/domain/entities/note.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_style.dart';

class HomeController extends GetxController {
  HomeController(
    this._getNotesUseCase,
    this._updateNoteUseCase,
    this._deleteNoteUseCase,
  );
  final GetNotesUseCase _getNotesUseCase;
  final UpdateNoteUseCase _updateNoteUseCase;
  final DeleteNoteUseCase _deleteNoteUseCase;
  
  // Note: We still use the interface for complex things like folders if not using specific use cases
  final NoteRepository _repository = Get.find<NoteRepository>();
  // Observable states
  final notes = <Note>[].obs;
  final folders = <Folder>[].obs;
  final trashNotes = <Note>[].obs;
  final pinnedNotes = <Note>[].obs;
  final filteredNotes = <Note>[].obs;
  final selectedFolder = Rxn<Folder>();
  final isFolderView = true.obs;
  final isSearching = false.obs;
  final isEditing = false.obs;
  final isGalleryView = false.obs;
  final isTrashView = false.obs;
  final searchQuery = ''.obs;
  final activeSearchToken = RxnString();
  final recentSearches = <String>[].obs;
  final isNotesSectionExpanded = true.obs;
  final isLocalSectionExpanded = true.obs;
  final isTagsSectionExpanded = true.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadNotes();
    _loadRecentSearches();
  }
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_searches') ?? [];
    recentSearches.assignAll(list);
  }
  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', recentSearches);
  }
  void addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    final trimmedQuery = query.trim();
    recentSearches.remove(trimmedQuery);
    recentSearches.insert(0, trimmedQuery);
    if (recentSearches.length > 10) {
      recentSearches.removeLast();
    }
    _saveRecentSearches();
  }

  void clearRecentSearches() {
    recentSearches.clear();
    _saveRecentSearches();
  }

  void removeRecentSearch(String query) {
    recentSearches.remove(query);
    _saveRecentSearches();
  }

  Future<void> loadNotes() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final activeNotes = await _getNotesUseCase();
      final deletedNotes = await _repository.getRecentlyDeleted();
      final allFolders = await _repository.getFolders();
      notes.assignAll(activeNotes);
      trashNotes.assignAll(deletedNotes);
      folders.assignAll(allFolders);
      _applyFilter();
    } catch (error) {
      errorMessage.value = 'Failed to load notes. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilter() {
    final baseNotes = selectedFolder.value == null
        ? notes
        : notes.where((note) => note.folderId == selectedFolder.value!.id);
    pinnedNotes.assignAll(baseNotes.where((n) => n.isPinned).toList());
    filteredNotes.assignAll(baseNotes.where((n) => !n.isPinned).toList());
  }
  void toggleViewMode() {
    isGalleryView.value = !isGalleryView.value;
    HapticFeedback.selectionClick();
  }

  Future<void> togglePin(Note note) async {
    // In Clean Architecture, we should ideally use a usecase that handles the mapping
    // But for brevity, I'll update the note entity (or a copy of it)
    // Entities should ideally be immutable and updated via repository
    // Note: Since I'm refactoring, I'll keep the logic simple
    final updatedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isDeleted: note.isDeleted,
      deletedAt: note.deletedAt,
      imagePaths: note.imagePaths,
      folderId: note.folderId,
      isPinned: !note.isPinned,
      isLocked: note.isLocked,
    );
    await _updateNoteUseCase(updatedNote);
    await loadNotes();
    HapticFeedback.mediumImpact();
  }
  void selectFolder(Folder? folder) {
    if (isEditing.value) return;
    selectedFolder.value = folder;
    isFolderView.value = false;
    isSearching.value = false;
    isTrashView.value = false;
    _applyFilter();
  }
  void toggleEdit() {
    isEditing.value = !isEditing.value;
  }
  void toggleNotesSection() {
    isNotesSectionExpanded.value = !isNotesSectionExpanded.value;
  }
  void toggleLocalSection() {
    isLocalSectionExpanded.value = !isLocalSectionExpanded.value;
  }
  void toggleTagsSection() {
    isTagsSectionExpanded.value = !isTagsSectionExpanded.value;
  }
  void showFolders() {
    isFolderView.value = true;
    isSearching.value = false;
    isEditing.value = false;
    isTrashView.value = false;
  }
  void showTrash() {
    isTrashView.value = true;
    isFolderView.value = false;
    isSearching.value = false;
    isEditing.value = false;
  }
  void startSearch() {
    isSearching.value = true;
    // When starting search from a folder, we search globally
    filteredNotes.assignAll(notes);
  }
  void cancelSearch() {
    isSearching.value = false;
    searchQuery.value = '';
    activeSearchToken.value = null;
    _applyFilter();
  }
  void search(String query) {
    searchQuery.value = query;
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) {
      // Show all active notes when query is empty but searching (Suggested view)
      filteredNotes.assignAll(notes);
      return;
    }
    final results = notes.where(
      (note) =>
          note.title.toLowerCase().contains(keyword) ||
          note.content.toLowerCase().contains(keyword) ||
          note.imagePaths.any((path) => path.toLowerCase().contains(keyword)),
    ).toList();
    filteredNotes.assignAll(results);
    // Add to recent searches if there are results and the query is long enough
    if (results.isNotEmpty && keyword.length > 2) {
      addRecentSearch(query);
    }
  }

  void searchByFilter(String type) {
    isSearching.value = true;
    switch (type) {
      case 'attachments':
        filteredNotes.assignAll(notes.where((n) => n.imagePaths.isNotEmpty));
        activeSearchToken.value = 'Attachments';
        break;
      case 'shared':
        _showStatusSnackbar('Shared Notes', 'Sharing features are coming soon!');
        filteredNotes.assignAll([]); // Implementation for shared notes
        activeSearchToken.value = 'Shared';
        break;
      case 'drawings':
        filteredNotes.assignAll(notes.where((n) => n.imagePaths.any((p) => p.contains('sketch') || p.contains('drawing'))));
        activeSearchToken.value = 'Drawings';
        break;
      case 'checklists':
        filteredNotes.assignAll(notes.where((n) => n.content.contains('☐') || n.content.contains('☑')));
        activeSearchToken.value = 'Checklists';
        break;
      case 'tags':
        filteredNotes.assignAll(notes.where((n) => n.content.contains('#')));
        activeSearchToken.value = 'Tags';
        break;
      case 'locked':
        filteredNotes.assignAll(notes.where((n) => n.isLocked));
        activeSearchToken.value = 'Locked';
        break;
      case 'scanned':
        _showStatusSnackbar('Scanned Documents', 'Document scanning is not available.');
        filteredNotes.assignAll([]); // Implementation for scanned docs
        activeSearchToken.value = 'Scanned';
        break;
    }
  }

  void removeSearchToken() {
    activeSearchToken.value = null;
    search(searchQuery.value);
  }
  Future<void> openCreateNote() async {
    HapticFeedback.lightImpact();
    final changed = await Get.toNamed(AppRoutes.editor);
    if (changed == true) await loadNotes();
  }
  Future<void> openCreateFolder() async {
    HapticFeedback.lightImpact();
    final res = await Get.to<String>(() => const CreateFolderView(), fullscreenDialog: true);
    if (res != null) { 
      await _repository.createFolder(res); 
      await loadNotes(); 
    }
  }
  Future<void> openNote(Note note) async {
    HapticFeedback.selectionClick();
    final changed = await Get.toNamed(AppRoutes.detail, arguments: note.id);
    if (changed == true) await loadNotes();
  }
  void goToSettings() {
    HapticFeedback.lightImpact();
    Get.toNamed(AppRoutes.settings);
  }
  Future<void> deleteNote(Note note) async {
    if (note.id == null) return;
    HapticFeedback.mediumImpact();
    final deletedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isDeleted: true,
      deletedAt: DateTime.now(),
      imagePaths: note.imagePaths,
      folderId: note.folderId,
      isPinned: note.isPinned,
      isLocked: note.isLocked,
    );
    await _updateNoteUseCase(deletedNote);
    await loadNotes();
    _showStatusSnackbar('Moved to Trash', 'Note moved to Recently Deleted.');
  }
  Future<void> restoreNote(Note note) async {
    if (note.id == null) return;
    HapticFeedback.mediumImpact();
    final restoredNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      isDeleted: false,
      deletedAt: null,
      imagePaths: note.imagePaths,
      folderId: note.folderId,
      isPinned: note.isPinned,
      isLocked: note.isLocked,
    );
    await _updateNoteUseCase(restoredNote);
    await loadNotes();
    _showStatusSnackbar('Restored', 'Note restored successfully.');
  }
  Future<void> permanentlyDeleteNote(Note note) async {
    if (note.id == null) return;
    HapticFeedback.heavyImpact();
    await _deleteNoteUseCase(note.id!);
    await loadNotes();
    _showStatusSnackbar('Deleted', 'Note permanently deleted.', isDestructive: true);
  }
  Future<void> clearTrash() async {
    if (trashNotes.isEmpty) return;
    Get.dialog(
      CupertinoAlertDialog(
        title:   Text('Empty Trash?'),
        content: Text('All notes in Recently Deleted will be permanently removed. This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Get.back();
              for (var note in trashNotes) {
                if (note.id != null) {
                  await _deleteNoteUseCase(note.id!);
                }
              }
              await loadNotes();
              _showStatusSnackbar('Trash Emptied', 'All deleted notes removed.', isDestructive: true);
            },
            child:  Text('Empty Trash'),
          ),
        ],
      ),
    );
  }
  void shareNote(Note note) {
    HapticFeedback.selectionClick();
    Get.bottomSheet(
      ShareBottomSheet(note: NoteModel.fromEntity(note)),
      isScrollControlled: true,
      enableDrag: true,
    );
  }
  void moveNote(Note note) {
    HapticFeedback.selectionClick();
    Get.bottomSheet(
      MoveNoteSheet(
        note: NoteModel.fromEntity(note),
        onMove: (folderId) async {
          final noteModel = NoteModel.fromEntity(note);
          final updatedNote = noteModel.copyWith(
            folderId: folderId,
            updatedAt: DateTime.now(),
          );
          await _updateNoteUseCase(updatedNote);
          await loadNotes();
          _showStatusSnackbar('Moved', 'Note moved successfully.');
        },
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }
  void openRecentlyDeleted() {
    if (isEditing.value) return;
    HapticFeedback.selectionClick();
    showTrash();
  }
  Future<void> deleteFolder(Folder folder) async {
    if (folder.id == null) return;
    Get.dialog(
      CupertinoAlertDialog(
        title: Text('Delete "${folder.name}"?'),
        content: Text('This folder will be deleted. Any notes inside will be kept but unorganized.'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Get.back();
              await _repository.deleteFolder(folder.id!);
              await loadNotes();
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
  Future<void> renameFolder(Folder folder) async {
    if (folder.id == null) return;
    final textController = TextEditingController(text: folder.name);
    Get.dialog(
      CupertinoAlertDialog(
        title: Text('Rename Folder'),
        content: Padding(
          padding: EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Folder Name',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty && newName != folder.name) {
                await _repository.renameFolder(folder.id!, newName);
                await loadNotes();
              }
              Get.back();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
  void _showStatusSnackbar(String title, String message, {bool isDestructive = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isDestructive ? HomeStyle.red : HomeStyle.blue,
      colorText: Colors.white,
      borderRadius: 15,
      margin: EdgeInsets.all(15),
      duration: Duration(seconds: 2),
      icon: Icon(
        isDestructive ? CupertinoIcons.trash_fill : CupertinoIcons.info_circle_fill,
        color: Colors.white,
      ),
    );
  }
}
