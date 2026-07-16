import 'package:notes/features/notes/domain/entities/note.dart';

/// Typed payload accepted by the note editor route.
final class NoteEditorArguments {
  const NoteEditorArguments.create({this.folderId}) : note = null;

  const NoteEditorArguments.edit(this.note) : folderId = null;

  final Note? note;
  final int? folderId;

  factory NoteEditorArguments.from(Object? value) {
    return switch (value) {
      final Note note => NoteEditorArguments.edit(note),
      final int folderId => NoteEditorArguments.create(folderId: folderId),
      _ => const NoteEditorArguments.create(),
    };
  }
}

enum EditorResult { saved, deleted }

/// Typed payload accepted by the note detail route.
final class NoteDetailArguments {
  const NoteDetailArguments(this.noteId);

  final int noteId;

  static int? noteIdFrom(Object? value) {
    return switch (value) {
      NoteDetailArguments(:final noteId) => noteId,
      final int noteId => noteId,
      _ => null,
    };
  }
}

/// Typed payload accepted by the login route after registration.
final class LoginArguments {
  const LoginArguments({this.phone});

  final String? phone;

  factory LoginArguments.from(Object? value) {
    if (value is LoginArguments) return value;
    if (value is Map) return LoginArguments(phone: value['phone']?.toString());
    return const LoginArguments();
  }
}
