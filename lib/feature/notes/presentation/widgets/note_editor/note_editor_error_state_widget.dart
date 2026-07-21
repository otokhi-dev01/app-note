part of '../../view/note_editor_view.dart';

class _NoteEditorErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _NoteEditorErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              // child: Icon(
              //   CupertinoIcons
              //       .exclamationmark_icloud_fill,
              //   size: 38,
              //   color: colors.error,
              // ),
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to Load Note',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message.isEmpty
                  ? 'Something went wrong while '
                        'loading this note.'
                  : message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
