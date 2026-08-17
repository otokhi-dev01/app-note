import 'package:intl/intl.dart';

/// One relative-date ladder for every note tile.
///
/// There used to be five near-identical `_formatTime` helpers that had drifted
/// apart — the list showed a weekday where archive showed `MM/dd/yy`, and the
/// grid showed `MMM d` — so the same note read differently on each screen.
class DateFormatter {
  DateFormatter._();

  /// `14:32` today · `Tuesday` this week · `Mar 4` this year · `03/04/24` older.
  static String relative(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();

    if (_isSameDay(date, now)) return DateFormat('HH:mm').format(date);

    final daysAgo = _startOfDay(now).difference(_startOfDay(date)).inDays;
    if (daysAgo > 0 && daysAgo < 7) return DateFormat('EEEE').format(date);

    if (date.year == now.year) return DateFormat('MMM d').format(date);

    return DateFormat('MM/dd/yy').format(date);
  }

  /// The header a note is filed under when the list is grouped by date.
  static String monthKey(DateTime? date) =>
      date == null ? 'Earlier' : DateFormat('MMMM').format(date);

  /// `March 4, 2026 at 2:32 PM` — the editor's timestamp line.
  static String full(DateTime? date) =>
      date == null ? '' : DateFormat("MMMM d, yyyy 'at' h:mm a").format(date);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}
