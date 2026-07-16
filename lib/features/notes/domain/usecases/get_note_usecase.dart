import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNoteUseCase {
  final NoteRepository repository;

  GetNoteUseCase(this.repository);

  Future<Note?> call(int id) {
    return repository.getNoteById(id);
  }
}
