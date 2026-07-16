import '../entities/note.dart';
import '../entities/folder.dart';

abstract class NoteRepository {
  Future<List<Note>> getNotes({bool includeDeleted = false});
  Future<List<Note>> getRecentlyDeleted();
  Future<Note?> getNoteById(int id);
  Future<int> createNote(Note note);
  Future<int> updateNote(Note note);
  Future<int> deleteNote(int id);

  // Folders
  Future<List<Folder>> getFolders();
  Future<int> createFolder(String name);
  Future<int> renameFolder(int id, String newName);
  Future<int> deleteFolder(int id);
  Future<int> restoreFolder(int id);
}
