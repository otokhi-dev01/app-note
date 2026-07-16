import '../../domain/entities/note.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/note_repository.dart';
import '../../core/database/database_service.dart';
import '../models/note_model.dart';
import '../models/folder_model.dart';
import '../services/auth_service.dart';
import '../services/folder_api_service.dart';
import '../services/note_api_service.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(
    this._databaseService,
    this._authService,
    this._folderApiService,
    this._noteApiService,
  );

  final DatabaseService _databaseService;
  final AuthService _authService;
  final FolderApiService _folderApiService;
  final NoteApiService _noteApiService;

  String get _ownerId {
    final ownerId = _authService.accountScopeId;
    if (ownerId == null) {
      throw StateError('An authenticated account is required.');
    }
    return ownerId;
  }

  @override
  Future<List<Note>> getNotes({bool includeDeleted = false}) async {
    try {
      final remoteNotes = await _noteApiService.getNotes(
        includeDeleted: includeDeleted,
      );
      await _cacheNotes(
        remoteNotes,
        replaceRemote: true,
        includeDeleted: includeDeleted,
      );
    } on NoteApiException {
      // Use the last account-scoped snapshot while the API is unavailable.
    }
    final rows = await _databaseService.getNotes(
      ownerId: _ownerId,
      includeDeleted: includeDeleted,
    );
    return rows.map(NoteModel.fromMap).toList(growable: false);
  }

  @override
  Future<List<Note>> getRecentlyDeleted() async {
    try {
      final remoteNotes = await _noteApiService.getNotes(includeDeleted: true);
      await _cacheNotes(remoteNotes, replaceRemote: true, includeDeleted: true);
    } on NoteApiException {
      // Use the cached trash while the API is unavailable.
    }
    final rows = await _databaseService.getRecentlyDeleted(ownerId: _ownerId);
    return rows.map(NoteModel.fromMap).toList(growable: false);
  }

  @override
  Future<Note?> getNoteById(int id) async {
    if (id <= 0) {
      final local = await _databaseService.getNoteById(
        id,
        ownerId: _ownerId,
        includeDeleted: true,
      );
      return local == null ? null : NoteModel.fromMap(local);
    }
    try {
      final remote = await _noteApiService.getNote(id);
      if (remote != null) {
        await _cacheNotes([remote]);
      }
    } on NoteApiException {
      // Read the account-scoped cache while offline.
    }
    final row = await _databaseService.getNoteById(
      id,
      ownerId: _ownerId,
      includeDeleted: true,
    );
    return row == null ? null : NoteModel.fromMap(row);
  }

  @override
  Future<int> createNote(Note note) async {
    final model = NoteModel.fromEntity(note);
    final remote = await _noteApiService.saveContent(model);
    final cached = _withLocalAttachments(remote, model);
    await _cacheNotes([cached]);
    return cached.id!;
  }

  @override
  Future<int> updateNote(Note note) async {
    final model = NoteModel.fromEntity(note);
    if (model.id == null) {
      throw ArgumentError('Note ID is required for update.');
    }
    final localRow = await _databaseService.getNoteById(
      model.id!,
      ownerId: _ownerId,
      includeDeleted: true,
    );
    final previous = localRow == null ? null : NoteModel.fromMap(localRow);

    if (model.id! <= 0) {
      final created = await _noteApiService.saveContent(model);
      final synced = _withLocalAttachments(
        created.copyWith(
          isDeleted: model.isDeleted,
          deletedAt: model.deletedAt,
          isPinned: model.isPinned,
          isLocked: model.isLocked,
        ),
        model,
      );
      await _sendStateChanges(null, synced);
      await _cacheNotes([synced]);
      await _databaseService.deleteNote(model.id!, ownerId: _ownerId);
      return 1;
    }

    final contentChanged =
        previous == null ||
        previous.title != model.title ||
        previous.content != model.content;
    if (contentChanged) {
      final saved = await _noteApiService.saveContent(model);
      await _cacheNotes([_withLocalAttachments(saved, model)]);
    }
    await _sendStateChanges(previous, model);

    // Upsert the confirmed state before the local update so a note opened
    // directly from a deep link is cached even when it was not in the list.
    await _cacheNotes([model]);
    final updated = await _databaseService.updateNote(model, ownerId: _ownerId);
    return updated == 0 ? 1 : updated;
  }

  @override
  Future<int> deleteNote(int id) async {
    if (id > 0) {
      throw UnsupportedError(
        'Permanent deletion is not available in the current note API. '
        'You can keep the note in Recently Deleted or restore it.',
      );
    }
    return _databaseService.deleteNote(id, ownerId: _ownerId);
  }

  @override
  Future<List<Folder>> getFolders() async {
    final localRows = await _databaseService.getFolders(ownerId: _ownerId);
    final localFolders = localRows.map(FolderModel.fromMap).toList();
    try {
      final remoteFolders = await _folderApiService.getFolders();
      await _cacheFolders(remoteFolders);
      final merged = <int, FolderModel>{
        for (final folder in localFolders)
          if (folder.id != null) folder.id!: folder,
        for (final folder in remoteFolders)
          if (folder.id != null) folder.id!: folder,
      };
      return merged.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } on FolderApiException {
      return localFolders;
    }
  }

  @override
  Future<int> createFolder(String name) async {
    try {
      final remote = await _folderApiService.saveFolder(name: name);
      if (remote != null) {
        await _cacheFolders([remote]);
        return remote.id!;
      }
    } on FolderApiException {
      // Keep folder creation usable offline. The cache remains scoped to the
      // authenticated account and the next successful refresh is server-first.
    }
    final folder = FolderModel(name: name.trim(), createdAt: DateTime.now());
    return _databaseService.insertFolder(
      folder.toMap()..remove('id'),
      ownerId: _ownerId,
    );
  }

  @override
  Future<int> renameFolder(int id, String newName) async {
    try {
      final remote = await _folderApiService.saveFolder(id: id, name: newName);
      if (remote != null) await _cacheFolders([remote]);
    } on FolderApiException {
      // Apply the change to the offline cache when the API is unavailable.
    }
    return _databaseService.updateFolder(id, newName.trim(), ownerId: _ownerId);
  }

  @override
  Future<int> deleteFolder(int id) async {
    try {
      await _folderApiService.setFolderDeleted(id, deleted: true);
    } on FolderApiException {
      // Delete locally while offline; the remote list remains authoritative
      // after the next successful authenticated refresh.
    }
    return _databaseService.deleteFolder(id, ownerId: _ownerId);
  }

  @override
  Future<int> restoreFolder(int id) async {
    await _folderApiService.setFolderDeleted(id, deleted: false);
    final remoteFolders = await _folderApiService.getFolders();
    await _cacheFolders(remoteFolders);
    return remoteFolders.any((folder) => folder.id == id) ? 1 : 0;
  }

  Future<void> _cacheFolders(List<FolderModel> folders) {
    return _databaseService.cacheRemoteFolders(
      folders.map((folder) => folder.toMap()).toList(growable: false),
      ownerId: _ownerId,
    );
  }

  Future<void> _cacheNotes(
    List<NoteModel> notes, {
    bool replaceRemote = false,
    bool includeDeleted = false,
  }) {
    return _databaseService.cacheRemoteNotes(
      notes,
      ownerId: _ownerId,
      replaceRemote: replaceRemote,
      includeDeleted: includeDeleted,
    );
  }

  Future<void> _sendStateChanges(NoteModel? previous, NoteModel current) async {
    if ((previous == null && current.isDeleted) ||
        (previous != null && previous.isDeleted != current.isDeleted)) {
      await _noteApiService.updateState(
        current,
        state: 'deleted',
        value: current.isDeleted,
      );
    }
    if ((previous == null && current.isPinned) ||
        (previous != null && previous.isPinned != current.isPinned)) {
      await _noteApiService.updateState(
        current,
        state: 'pinned',
        value: current.isPinned,
      );
    }
    if ((previous == null && current.isLocked) ||
        (previous != null && previous.isLocked != current.isLocked)) {
      await _noteApiService.updateState(
        current,
        state: 'locked',
        value: current.isLocked,
      );
    }
    if (previous != null && previous.folderId != current.folderId) {
      await _noteApiService.updateState(
        current,
        state: 'folder',
        value: current.folderId,
      );
    }
  }

  NoteModel _withLocalAttachments(NoteModel remote, NoteModel local) {
    final paths = <String>{...remote.imagePaths};
    for (final path in local.imagePaths) {
      final uri = Uri.tryParse(path.trim());
      final isNetwork =
          uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
      if (!isNetwork) paths.add(path);
    }
    return remote.copyWith(imagePaths: paths.toList(growable: false));
  }
}
