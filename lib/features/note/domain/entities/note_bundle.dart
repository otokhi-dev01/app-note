import 'package:Note/features/note/domain/entities/note.dart';

/// The three buckets `/api/note` returns in one trip: active notes, archived
/// notes, and the trash. Screens each read a different slice of the same fetch.
class NoteBundle {
  final List<Note> notes;
  final List<Note> archive;
  final List<Note> trash;

  const NoteBundle({
    this.notes = const [],
    this.archive = const [],
    this.trash = const [],
  });

  const NoteBundle.empty() : this();
}
