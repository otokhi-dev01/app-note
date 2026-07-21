part of 'home_server_error_state_widget.dart';

class HomeEmptyNotesState extends StatelessWidget {
  final bool hasFolders;
  final VoidCallback onCreateFolder;
  final VoidCallback onCreateNote;

  const HomeEmptyNotesState({
    super.key,
    required this.hasFolders,
    required this.onCreateFolder,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 30, 34, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.10),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                hasFolders
                    ? Icons.note_add_outlined
                    : Icons.create_new_folder_outlined,
                size: 38,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 21),
            Text(
              hasFolders ? 'No notes yet' : 'Create your first folder',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              hasFolders
                  ? 'Capture an idea, task, document, '
                        'or checklist.'
                  : 'Folders help keep your notes '
                        'organized.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 21),
            FilledButton.icon(
              onPressed: hasFolders ? onCreateNote : onCreateFolder,
              icon: Icon(
                hasFolders
                    ? Icons.add_rounded
                    : Icons.create_new_folder_outlined,
              ),
              label: Text(hasFolders ? 'Create Note' : 'Create Folder'),
            ),
          ],
        ),
      ),
    );
  }
}
