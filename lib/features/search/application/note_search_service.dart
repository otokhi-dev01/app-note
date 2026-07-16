import 'package:notes/features/notes/domain/entities/note.dart';

final class NoteSearchService {
  const NoteSearchService();

  List<Note> matchingText(Iterable<Note> notes, String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return List<Note>.of(notes);

    return notes
        .where(
          (note) =>
              note.title.toLowerCase().contains(keyword) ||
              note.content.toLowerCase().contains(keyword) ||
              note.imagePaths.any(
                (path) => path.toLowerCase().contains(keyword),
              ),
        )
        .toList(growable: false);
  }

  List<Note> matchingFilter(Iterable<Note> notes, String type) {
    return switch (type) {
      'attachments' =>
        notes
            .where((note) => note.imagePaths.isNotEmpty)
            .toList(growable: false),
      'drawings' =>
        notes
            .where(
              (note) => note.imagePaths.any(
                (path) => path.contains('sketch') || path.contains('drawing'),
              ),
            )
            .toList(growable: false),
      'checklists' =>
        notes
            .where(
              (note) =>
                  note.content.contains('☐') || note.content.contains('☑'),
            )
            .toList(growable: false),
      'tags' =>
        notes
            .where((note) => note.content.contains('#'))
            .toList(growable: false),
      'locked' => notes.where((note) => note.isLocked).toList(growable: false),
      'shared' || 'scanned' => const <Note>[],
      _ => List<Note>.of(notes),
    };
  }

  List<Note> matchingCategory(Iterable<Note> notes, String category) {
    final keyword = category.toLowerCase();
    final patterns = switch (keyword) {
      'receipts' => const ['receipt', 'invoice', 'total', 'purchase'],
      'travel' => const ['travel', 'trip', 'flight', 'hotel'],
      'work' => const ['work', 'project', 'meeting', 'client'],
      'personal' => const ['personal', 'home', 'family', 'journal'],
      _ => [keyword],
    };

    return notes
        .where((note) {
          final haystack = '${note.title} ${note.content}'.toLowerCase();
          return patterns.any(haystack.contains);
        })
        .toList(growable: false);
  }
}
