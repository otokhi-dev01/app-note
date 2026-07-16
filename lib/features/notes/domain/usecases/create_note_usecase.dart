import '../entities/note.dart';
import '../repositories/note_repository.dart';

class CreateNoteUseCase {
  final NoteRepository repository;
  CreateNoteUseCase(this.repository);

  Future<int> call(Note note) {
    return repository.createNote(note);
  }
}
