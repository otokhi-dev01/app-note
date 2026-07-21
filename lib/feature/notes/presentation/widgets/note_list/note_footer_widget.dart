part of '../../view/note_list_view.dart';

class _NoteFooter extends StatelessWidget {
  final int count;

  const _NoteFooter({required this.count});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        '$count '
        '${count == 1 ? 'note' : 'notes'}',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}
