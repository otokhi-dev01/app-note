part of '../../view/note_list_view.dart';

class _NoNoteResultsState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _NoNoteResultsState({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _StateIcon(
              icon: CupertinoIcons.search,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 18),
            Text(
              'No Notes Found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No results for “$query”.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onClear, child: const Text('Clear Search')),
          ],
        ),
      ),
    );
  }
}
