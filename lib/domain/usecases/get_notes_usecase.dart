import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotesUseCase {
  final NoteRepository repository;

  GetNotesUseCase(this.repository);

  Future<List<Note>> call({bool includeDeleted = false}) {
    return repository.getNotes(includeDeleted: includeDeleted);
  }
}
