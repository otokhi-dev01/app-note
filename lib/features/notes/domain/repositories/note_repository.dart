import '../entities/note.dart';
import 'folder_repository.dart';

abstract class NoteRepository implements FolderRepository {
  Future<List<Note>> getNotes({bool includeDeleted = false});
  Future<List<Note>> getRecentlyDeleted();
  Future<Note?> getNoteById(int id);
  Future<int> createNote(Note note);
  Future<int> updateNote(Note note);
  Future<int> deleteNote(int id);
}
