import 'package:flutter/material.dart';
import 'glass_surface_widget.dart';

class HomeServerErrorState
    extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const HomeServerErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Center(
      child: GlassSurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.error.withValues(
                  alpha: 0.12,
                ),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 34,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style:
              theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon:
              const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeEmptyNotesState
    extends StatelessWidget {
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
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          34,
          30,
          34,
          120,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                colorScheme.primary.withValues(
                  alpha: 0.10,
                ),
                border: Border.all(
                  color:
                  colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                ),
              ),
              child: Icon(
                hasFolders
                    ? Icons.note_add_outlined
                    : Icons
                    .create_new_folder_outlined,
                size: 38,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 21),
            Text(
              hasFolders
                  ? 'No notes yet'
                  : 'Create your first folder',
              textAlign: TextAlign.center,
              style:
              theme.textTheme.headlineSmall
                  ?.copyWith(
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
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                color:
                colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 21),
            FilledButton.icon(
              onPressed: hasFolders
                  ? onCreateNote
                  : onCreateFolder,
              icon: Icon(
                hasFolders
                    ? Icons.add_rounded
                    : Icons
                    .create_new_folder_outlined,
              ),
              label: Text(
                hasFolders
                    ? 'Create Note'
                    : 'Create Folder',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeLoadingState extends StatelessWidget {
  const HomeLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator.adaptive(
            valueColor:
            AlwaysStoppedAnimation<Color>(
              colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your notes...',
            style: TextStyle(
              color:
              colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}