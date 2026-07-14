import 'package:notes/data/models/note_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const _databaseName = 'clean_notes.db';
  static const _databaseVersion = 5;
  static const notesTable = 'notes';
  static const foldersTable = 'folders';

  Database? _database;

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
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $notesTable ADD COLUMN is_deleted INTEGER DEFAULT 0');
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
      await db.execute('ALTER TABLE $notesTable ADD COLUMN is_pinned INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE $notesTable ADD COLUMN is_locked INTEGER DEFAULT 0');
    }
  }

  // Folder Methods
  Future<List<Map<String, Object?>>> getFolders() async {
    final db = await database;
    return db.query(foldersTable, orderBy: 'name ASC');
  }

  Future<int> insertFolder(Map<String, Object?> folder) async {
    final db = await database;
    return db.insert(foldersTable, folder);
  }

  Future<int> updateFolder(int id, String name) async {
    final db = await database;
    return db.update(
      foldersTable,
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await database;
    // We don't delete notes in the folder, just set folder_id to null (handled by SQLite if set up, but let's be explicit if needed)
    await db.update(notesTable, {'folder_id': null}, where: 'folder_id = ?', whereArgs: [id]);
    return db.delete(foldersTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getNotes({bool includeDeleted = false}) async {
    final db = await database;
    return db.query(
      notesTable,
      where: includeDeleted ? null : 'is_deleted = 0',
      orderBy: 'updated_at DESC',
    );
  }

  Future<List<Map<String, Object?>>> getRecentlyDeleted() async {
    final db = await database;
    return db.query(
      notesTable,
      where: 'is_deleted = 1',
      orderBy: 'deleted_at DESC',
    );
  }

  Future<Map<String, Object?>?> getNoteById(int id) async {
    final db = await database;
    final rows = await db.query(
      notesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  Future<int> insertNote(NoteModel note) async {
    final db = await database;
    return db.insert(notesTable, note.toMap()..remove('id'));
  }

  Future<int> updateNote(NoteModel note) async {
    if (note.id == null) {
      throw ArgumentError('Note ID is required for update.');
    }

    final db = await database;
    return db.update(
      notesTable,
      note.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return db.delete(
      notesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
