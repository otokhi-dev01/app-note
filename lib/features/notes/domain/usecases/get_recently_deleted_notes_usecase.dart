import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetRecentlyDeletedNotesUseCase {
  const GetRecentlyDeletedNotesUseCase(this.repository);

  final NoteRepository repository;

  Future<List<Note>> call() {
    return repository.getRecentlyDeleted();
  }
}
