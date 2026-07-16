part of '../home_view.dart';

List<String> _extractTags(List<Note> notes) {
  final counts = <String, int>{};
  final expression = RegExp(r'#[a-zA-Z0-9_-]+');
  for (final note in notes) {
    for (final match in expression.allMatches(note.content)) {
      final tag = match.group(0)!.toLowerCase();
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final tags = entries.take(8).map((entry) => entry.key).toList();
  return tags.isEmpty
      ? ['#inspiration', '#work', '#personal', '#travel']
      : tags;
}

String _shortDate(DateTime date) {
  final now = DateTime.now();
  if (DateUtils.isSameDay(date, now)) return DateFormat.jm().format(date);
  if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  }
  return DateFormat.MMMd().format(date);
}

int _wordCount(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
}

TextStyle _eyebrowStyle(BuildContext context) => TextStyle(
  color: Theme.of(context).colorScheme.onSurfaceVariant,
  fontSize: 12,
  letterSpacing: 1.25,
  fontWeight: FontWeight.w700,
);
