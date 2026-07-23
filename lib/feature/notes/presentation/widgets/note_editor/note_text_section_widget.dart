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
              fontSize: 26,
            ),
          ),

          const SizedBox(height: 12),

          Obx(() {
            final folderName = controller.note.value?.folderName ?? 'Work';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                folderName,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          GestureDetector(
            onLongPress: () {
              if (controller.canEdit) {
                HapticFeedback.mediumImpact();
                // This will trigger the global long press handler in NoteEditorView 
                // but we can also call it directly if preferred.
                // For consistency with CreateNoteView, let's ensure it works here.
              }
            },
            child: CupertinoTextField(
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
          ),
        ],
      ),
    );
  }
}
