part of '../../view/note_list_view.dart';

class _NoteErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _NoteErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _StateIcon(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              color: colors.error,
            ),
            const SizedBox(height: 18),
            Text(
              'Notes Are Unavailable',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message.isEmpty ? 'Unable to load your notes.' : message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
