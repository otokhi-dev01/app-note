import 'package:notes/features/notes/domain/entities/note.dart';

abstract interface class AttachmentSizeQuery {
  Future<int> calculate(List<Note> notes);
}
