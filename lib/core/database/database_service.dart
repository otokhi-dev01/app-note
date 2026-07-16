import 'package:notes/data/models/note_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const _databaseName = 'clean_notes.db';
  static const _databaseVersion = 6;
  static const notesTable = 'notes';
  static const foldersTable = 'folders';
  static const _metadataTable = 'app_metadata';
  static const _legacyOwnerKey = 'legacy_data_owner';

  Database? _database;
  Future<void>? _legacyClaimFuture;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $notesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        deleted_at TEXT,
        image_paths TEXT,
        folder_id INTEGER,
        owner_id TEXT NOT NULL,
        is_pinned INTEGER DEFAULT 0,
        is_locked INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES $foldersTable (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $foldersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await _createOwnershipInfrastructure(db);
    await db.insert(_metadataTable, {
      'key': _legacyOwnerKey,
      'value': 'new_database',
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $notesTable ADD COLUMN is_deleted INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE $notesTable ADD COLUMN deleted_at TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $notesTable ADD COLUMN image_paths TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE $foldersTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('ALTER TABLE $notesTable ADD COLUMN folder_id INTEGER');
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE $notesTable ADD COLUMN is_pinned INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $notesTable ADD COLUMN is_locked INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE $notesTable ADD COLUMN owner_id TEXT');
      await db.execute('ALTER TABLE $foldersTable ADD COLUMN owner_id TEXT');
      await _createOwnershipInfrastructure(db);
    }
  }

  Future<void> _createOwnershipInfrastructure(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_metadataTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notes_owner_deleted_updated
      ON $notesTable (owner_id, is_deleted, updated_at)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_folders_owner_name
      ON $foldersTable (owner_id, name)
    ''');
  }

  String _normalizeOwnerId(String ownerId) {
    final normalized = ownerId.trim();
    if (normalized.isEmpty) {
      throw StateError('An authenticated account is required.');
    }
    return normalized;
  }

  Future<Database> _databaseForOwner(String ownerId) async {
    final db = await database;
    await _ensureLegacyRowsClaimed(db, ownerId);
    return db;
  }

  Future<void> _ensureLegacyRowsClaimed(Database db, String ownerId) async {
    final inFlight = _legacyClaimFuture;
    if (inFlight != null) return inFlight;

    final claim = db.transaction((transaction) async {
      final marker = await transaction.query(
        _metadataTable,
        columns: const ['value'],
        where: 'key = ?',
        whereArgs: const [_legacyOwnerKey],
        limit: 1,
      );
      if (marker.isNotEmpty) return;

      await transaction.update(foldersTable, {
        'owner_id': ownerId,
      }, where: 'owner_id IS NULL');
      await transaction.update(notesTable, {
        'owner_id': ownerId,
      }, where: 'owner_id IS NULL');
      await transaction.insert(_metadataTable, {
        'key': _legacyOwnerKey,
        'value': ownerId,
      });
    });
    _legacyClaimFuture = claim;

    try {
      await claim;
    } catch (_) {
      if (identical(_legacyClaimFuture, claim)) {
        _legacyClaimFuture = null;
      }
      rethrow;
    }
  }

  Future<void> _ensureFolderOwned(
    DatabaseExecutor executor,
    int? folderId,
    String ownerId,
  ) async {
    if (folderId == null) return;

    final folder = await executor.query(
      foldersTable,
      columns: const ['id'],
      where: 'id = ? AND owner_id = ?',
      whereArgs: [folderId, ownerId],
      limit: 1,
    );
    if (folder.isEmpty) {
      throw StateError(
        'The selected folder is not available for this account.',
      );
    }
  }

  // Folder Methods
  Future<List<Map<String, Object?>>> getFolders({
    required String ownerId,
  }) async {
    final owner = _normalizeOwnerId(ownerId);
    final db = await _databaseForOwner(owner);
    return db.query(
      foldersTable,
      where: 'owner_id = ?',
      whereArgs: [owner],
      orderBy: 'name ASC',
    );
  }

  Future<int> insertFolder(
    Map<String, Object?> folder, {
    required String ownerId,
  }) async {
    final owner = _normalizeOwnerId(ownerId);
    final db = await _databaseForOwner(owner);
    final values = Map<String, Object?>.from(folder)..['owner_id'] = owner;
    return db.insert(foldersTable, values);
  }

  Future<int> updateFolder(
    int id,
    String name, {
    required String ownerId,
  }) async {
    final owner = _normalizeOwnerId(ownerId);
    final db = await _databaseForOwner(owner);
    return db.update(
      foldersTable,
      {'name': name},
      where: 'id = ? AND owner_id = ?',
      whereArgs: [id, owner],
    );
  }

  Future<int> deleteFolder(int id, {required String ownerId}) async {
    final owner = _normalizeOwnerId(ownerId);
    final db = await _databaseForOwner(owner);
    return db.transaction((transaction) async {
      final folder = await transaction.query(
        foldersTable,
        columns: const ['id'],
        where: 'id = ? AND owner_id = ?',
        whereArgs: [id, owner],
        limit: 1,
      );
      if (folder.isEmpty) return 0;

      await transaction.update(
        notesTable,
        {'folder_id': null},
        where: 'folder_id = ? AND owner_id = ?',
        whereArgs: [id, owner],
      );
      return transaction.delete(
        foldersTable,
        where: 'id = ? AND owner_id = ?',
        whereArgs: [id, owner],
      );
    });
  }

  Future<List<Map<String, Object?>>> getNotes({
    required String ownerId,
    bool includeDeleted = false,
  }) async {
    final owner = _normalizeOwnerId(ownerId);
    final db = await _databaseForOwner(owner);
    return db.query(
      notesTable,
      where: includeDeleted
          ? 'owner_id = ?'
          : 'owner_id = ? AND is_deleted = 0',
      whereArgs: [owner],
      orderBy: 'updated_at DESC',
    );
  }

  Future<List<Map<String, Object?>>> getRecentlyDeleted({
    required String ownerId,
  }) async {
    final owner = _normalizeOwnerId(ownerId);
    final db = await _databaseForOwner(owner);
    return db.query(
      notesTable,
      where: 'owner_id = ? AND is_deleted = 1',
      whereArgs: [owner],
      orderBy: 'deleted_at DESC',
    );
  }

  Future<Map<String, Object?>?> getNoteById(
    int id, {
    required String ownerId,
  }) async {
    final owner = _normalizeOwnerId(ownerId);
    final db = await _databaseForOwner(owner);
    final rows = await db.query(
      notesTable,
      where: 'id = ? AND owner_id = ? AND is_deleted = 0',
      whereArgs: [id, owner],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  Future<int> insertNote(NoteModel note, {required String ownerId}) async {
    final owner = _normalizeOwnerId(ownerId);
    final db = await _databaseForOwner(owner);
    return db.transaction((transaction) async {
      await _ensureFolderOwned(transaction, note.folderId, owner);
      final values = note.toMap()
        ..remove('id')
        ..['owner_id'] = owner;
      return transaction.insert(notesTable, values);
    });
  }

  Future<int> updateNote(NoteModel note, {required String ownerId}) async {
    if (note.id == null) {
      throw ArgumentError('Note ID is required for update.');
    }

    final owner = _normalizeOwnerId(ownerId);
    final db = await _databaseForOwner(owner);
    return db.transaction((transaction) async {
      await _ensureFolderOwned(transaction, note.folderId, owner);
      final values = note.toMap()
        ..remove('id')
        ..remove('owner_id');
      return transaction.update(
        notesTable,
        values,
        where: 'id = ? AND owner_id = ?',
        whereArgs: [note.id, owner],
      );
    });
  }

  Future<int> deleteNote(int id, {required String ownerId}) async {
    final owner = _normalizeOwnerId(ownerId);
    final db = await _databaseForOwner(owner);
    return db.delete(
      notesTable,
      where: 'id = ? AND owner_id = ?',
      whereArgs: [id, owner],
    );
  }
}
