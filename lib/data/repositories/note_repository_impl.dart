import '../../domain/entities/note.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/note_repository.dart';
import '../../core/database/database_service.dart';
import '../models/note_model.dart';
import '../models/folder_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._databaseService);

  final DatabaseService _databaseService;

  @override
  Future<List<Note>> getNotes({bool includeDeleted = false}) async {
    final rows = await _databaseService.getNotes(includeDeleted: includeDeleted);
    return rows.map(NoteModel.fromMap).toList();
  }

  @override
  Future<List<Note>> getRecentlyDeleted() async {
    final rows = await _databaseService.getRecentlyDeleted();
    return rows.map(NoteModel.fromMap).toList();
  }

  @override
  Future<Note?> getNoteById(int id) async {
    final row = await _databaseService.getNoteById(id);
    return row == null ? null : NoteModel.fromMap(row);
  }

  @override
  Future<int> createNote(Note note) {
    return _databaseService.insertNote(NoteModel.fromEntity(note));
  }

  @override
  Future<int> updateNote(Note note) {
    return _databaseService.updateNote(NoteModel.fromEntity(note));
  }

  @override
  Future<int> deleteNote(int id) {
    return _databaseService.deleteNote(id);
  }

  @override
  Future<List<Folder>> getFolders() async {
    final rows = await _databaseService.getFolders();
    return rows.map(FolderModel.fromMap).toList();
  }

  @override
  Future<int> createFolder(String name) {
    final folder = FolderModel(name: name, createdAt: DateTime.now());
    return _databaseService.insertFolder(folder.toMap()..remove('id'));
  }

  @override
  Future<int> renameFolder(int id, String newName) {
    return _databaseService.updateFolder(id, newName);
  }

  @override
  Future<int> deleteFolder(int id) {
    return _databaseService.deleteFolder(id);
  }
}
