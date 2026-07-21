part of '../../view/note_list_view.dart';

class _NoteCountSummary extends StatelessWidget {
  final int count;

  const _NoteCountSummary({required this.count});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 2),
      child: Text(
        '$count '
        '${count == 1 ? 'note' : 'notes'}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
