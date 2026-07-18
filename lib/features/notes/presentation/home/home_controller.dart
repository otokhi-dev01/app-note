import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/app/navigation/route_contracts.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes/features/library/application/library_coordinator.dart';
import 'package:notes/features/notes/domain/entities/folder.dart';
import 'package:notes/features/notes/domain/entities/note.dart';
import 'package:notes/features/notes/domain/repositories/note_repository.dart';
import 'package:notes/features/notes/domain/repositories/attachment_file_repository.dart';
import 'package:notes/features/notes/domain/usecases/create_folder_usecase.dart';
import 'package:notes/features/notes/domain/usecases/delete_folder_usecase.dart';
import 'package:notes/features/notes/domain/usecases/delete_note_usecase.dart';
import 'package:notes/features/notes/domain/usecases/get_folders_usecase.dart';
import 'package:notes/features/notes/domain/usecases/get_deleted_folders_usecase.dart';
import 'package:notes/features/notes/domain/usecases/get_notes_usecase.dart';
import 'package:notes/features/notes/domain/usecases/get_recently_deleted_notes_usecase.dart';
import 'package:notes/features/notes/domain/usecases/rename_folder_usecase.dart';
import 'package:notes/features/notes/domain/usecases/restore_folder_usecase.dart';
import 'package:notes/features/notes/domain/usecases/update_note_usecase.dart';
import 'package:notes/features/notes/presentation/home/widgets/create_folder_view.dart';
import 'package:notes/features/notes/presentation/home/widgets/home_sheets.dart';
import 'package:notes/features/search/application/note_search_service.dart';
import 'package:notes/features/search/domain/repositories/recent_search_repository.dart';

part 'controllers/home_feedback.dart';
part 'controllers/home_folder_actions.dart';
part 'controllers/home_note_actions.dart';
part 'controllers/home_search_navigation_actions.dart';

class HomeController extends GetxController implements LibraryCoordinator {
  HomeController(
    this._getNotesUseCase,
    this._updateNoteUseCase,
    this._deleteNoteUseCase, {
    NoteRepository? repository,
    AuthRepository? authRepository,
    RecentSearchRepository? recentSearchRepository,
    AttachmentFileRepository? attachmentFiles,
  }) : _repository = repository ?? Get.find<NoteRepository>(),
       _authRepository =
           authRepository ??
           (Get.isRegistered<AuthRepository>()
               ? Get.find<AuthRepository>()
               : null),
       _recentSearchRepository =
           recentSearchRepository ??
           (Get.isRegistered<RecentSearchRepository>()
               ? Get.find<RecentSearchRepository>()
               : const _TransientRecentSearchRepository()),
       _attachmentFiles =
           attachmentFiles ??
           (Get.isRegistered<AttachmentFileRepository>()
               ? Get.find<AttachmentFileRepository>()
               : null);

  final GetNotesUseCase _getNotesUseCase;
  final UpdateNoteUseCase _updateNoteUseCase;
  final DeleteNoteUseCase _deleteNoteUseCase;
  final NoteRepository _repository;
  final AuthRepository? _authRepository;
  final RecentSearchRepository _recentSearchRepository;
  final AttachmentFileRepository? _attachmentFiles;
  final _noteSearchService = const NoteSearchService();

  late final _getFolders = GetFoldersUseCase(_repository);
  late final _getDeletedFolders = GetDeletedFoldersUseCase(_repository);
  late final _getRecentlyDeletedNotes = GetRecentlyDeletedNotesUseCase(
    _repository,
  );
  late final _createFolder = CreateFolderUseCase(_repository);
  late final _deleteFolder = DeleteFolderUseCase(_repository);
  late final _renameFolder = RenameFolderUseCase(_repository);
  late final _restoreFolder = RestoreFolderUseCase(_repository);

  @override
  final notes = <Note>[].obs;
  final folders = <Folder>[].obs;
  final recentlyDeletedFolders = <Folder>[].obs;
  @override
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
  final isFolderSyncing = false.obs;
  final selectedTab = 0.obs;
  final selectedCalendarDay = DateTime.now().day.obs;
  final searchFieldController = TextEditingController();
  int _loadGeneration = 0;

  @override
  int get selectedCalendarDayValue => selectedCalendarDay.value;

  @override
  void setSelectedCalendarDay(int day) {
    selectedCalendarDay.value = day;
  }

  @override
  void onInit() {
    super.onInit();
    loadNotes();
    _loadRecentSearches();
  }

  @override
  Future<void> loadNotes() async {
    final generation = ++_loadGeneration;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      // Folders must be cached first so remote notes retain valid links.
      final allFolders = await _getFolders();
      final activeNotes = await _getNotesUseCase();
      List<Note> deletedNotes;
      try {
        deletedNotes = await _getRecentlyDeletedNotes();
      } catch (_) {
        // A trash sync problem must not hide successfully loaded active notes.
        deletedNotes = trashNotes.toList(growable: false);
      }
      if (generation != _loadGeneration) return;

      folders.assignAll(allFolders);
      notes.assignAll(activeNotes);
      trashNotes.assignAll(deletedNotes);
      try {
        recentlyDeletedFolders.assignAll(await _getDeletedFolders());
      } catch (_) {
        // A deleted-folders query failure must not hide loaded folders/notes.
      }
      if (isSearching.value) {
        final token = activeSearchToken.value;
        if (token != null) {
          searchByFilter(token.toLowerCase());
        } else {
          search(searchQuery.value);
        }
      } else {
        _applyFilter();
      }
    } catch (error) {
      if (generation == _loadGeneration) {
        errorMessage.value = 'Failed to sync notes. ${_readableError(error)}';
      }
    } finally {
      if (generation == _loadGeneration) isLoading.value = false;
    }
  }

  Future<void> syncFolders() => _syncFoldersAction();

  void addRecentSearch(String query) => _addRecentSearch(query);
  void clearRecentSearches() => _clearRecentSearches();
  void removeRecentSearch(String query) => _removeRecentSearch(query);
  void toggleViewMode() => _toggleViewMode();
  Future<void> togglePin(Note note) => _togglePin(note);
  void selectFolder(Folder? folder) => _selectFolder(folder);
  @override
  void selectTab(int index) => _selectTab(index);
  void toggleEdit() => _toggleEdit();
  void toggleNotesSection() => _toggleNotesSection();
  void toggleLocalSection() => _toggleLocalSection();
  void toggleTagsSection() => _toggleTagsSection();
  void showFolders() => _showFolders();
  @override
  void showTrash() => _showTrash();
  void startSearch() => _startSearch();
  void cancelSearch() => _cancelSearch();
  @override
  void search(String query) => _search(query);
  void searchByFilter(String type) => _searchByFilter(type);
  @override
  void searchCategory(String category) => _searchCategory(category);
  void removeSearchToken() => _removeSearchToken();
  @override
  Future<void> openCreateNote() => _openCreateNote();
  Future<void> openCreateFolder() => _openCreateFolder();
  @override
  Future<void> openNote(Note note) => _openNote(note);
  void goToSettings() => _goToSettings();
  Future<void> deleteNote(Note note) => _deleteNote(note);
  Future<void> restoreNote(Note note) => _restoreNote(note);
  Future<void> restoreAllNotes() => _restoreAllNotes();
  Future<void> permanentlyDeleteNote(Note note) => _permanentlyDeleteNote(note);
  Future<void> clearTrash() => _clearTrash();
  void shareNote(Note note) => _shareNote(note);
  void moveNote(Note note) => _moveNote(note);
  void openRecentlyDeleted() => _openRecentlyDeleted();
  Future<void> deleteFolder(Folder folder) => _deleteFolderAction(folder);
  Future<void> renameFolder(Folder folder) => _renameFolderAction(folder);
  Future<void> restoreFolder(Folder folder) => _restoreFolderAction(folder);

  @override
  void onClose() {
    searchFieldController.dispose();
    super.onClose();
  }
}
