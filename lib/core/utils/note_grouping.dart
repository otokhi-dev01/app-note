import 'package:Note/core/utils/date_formatter.dart';
import 'package:Note/features/note/domain/entities/note.dart';

/// Buckets notes under the section headers the lists show when grouping by
/// date: Today, Yesterday, Previous 7 Days, then by month.
///
/// The notes list and the archive each carried a byte-identical copy of this.
class NoteGrouping {
  NoteGrouping._();

  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String previousWeek = 'Previous 7 Days';

  /// Insertion order is preserved, so a caller that hands in a date-sorted list
  /// gets its sections back in that same order.
  static Map<String, List<Note>> byDate(List<Note> notes) {
    final groups = <String, List<Note>>{};
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    final sevenDaysAgo = startOfToday.subtract(const Duration(days: 7));

    for (final note in notes) {
      final date = note.updatedAt ?? now;
      final day = DateTime(date.year, date.month, date.day);

      final String key;
      if (day == startOfToday) {
        key = today;
      } else if (day == startOfYesterday) {
        key = yesterday;
      } else if (day.isAfter(sevenDaysAgo)) {
        key = previousWeek;
      } else {
        key = DateFormatter.monthKey(date);
      }

      groups.putIfAbsent(key, () => []).add(note);
    }

    return groups;
  }
}
