part of '../../view/note_list_view.dart';

class _EmptyNoteState extends StatelessWidget {
  final bool hasFolders;
  final VoidCallback onCreate;

  const _EmptyNoteState({required this.hasFolders, required this.onCreate});

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
              icon: hasFolders
                  ? CupertinoIcons.doc_text
                  : CupertinoIcons.folder_badge_plus,
              color: colors.primary,
            ),
            const SizedBox(height: 18),
            Text(
              hasFolders ? 'No Notes Yet' : 'Create a Folder First',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFolders
                  ? 'Create your first note '
                        'in this folder.'
                  : 'A folder is required '
                        'before creating a note.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (hasFolders) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(CupertinoIcons.add),
                label: const Text('Create Note'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
