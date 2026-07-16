import 'package:intl/intl.dart';
import 'package:notes/features/notes/domain/entities/note.dart';

Map<String, int> libraryTagCounts(List<Note> notes) {
  final counts = <String, int>{};
  final expression = RegExp(r'#[a-zA-Z0-9_-]+');
  for (final note in notes) {
    for (final match in expression.allMatches(note.content)) {
      final tag = match.group(0)!.toLowerCase();
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map<String, int>.fromEntries(sorted);
}

Map<String, List<Note>> groupNotesByDay(List<Note> notes, {DateTime? today}) {
  final groups = <String, List<Note>>{};
  final now = today ?? DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));

  for (final note in notes) {
    final key = _isSameDay(note.updatedAt, now)
        ? 'Today'
        : _isSameDay(note.updatedAt, yesterday)
        ? 'Yesterday'
        : DateFormat.yMMMd().format(note.updatedAt);
    groups.putIfAbsent(key, () => <Note>[]).add(note);
  }
  return groups;
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
