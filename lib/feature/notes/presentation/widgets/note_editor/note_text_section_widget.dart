part of '../../view/note_editor_view.dart';

class _NoteTextSection extends StatelessWidget {
  final NoteEditorController controller;

  const _NoteTextSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    return AppSurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CupertinoTextField(
            controller: controller.titleController,
            readOnly: controller.isLocked,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: 250,
            padding: EdgeInsets.zero,
            decoration: null,
            placeholder: 'Title',
            placeholderStyle: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
            ),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 12),

          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.45),
          ),

          const SizedBox(height: 14),

          CupertinoTextField(
            controller: controller.statementController,
            readOnly: controller.isLocked,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 12,
            maxLines: null,
            padding: EdgeInsets.zero,
            decoration: null,
            placeholder: 'Start writing your note...',
            placeholderStyle: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.55),
              height: 1.55,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
