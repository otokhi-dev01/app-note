part of '../../view/create_note_view.dart';

class _BodyField extends GetView<CreateNoteController> {
  const _BodyField();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return CupertinoTextField(
      controller: controller.statementController,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: 14,
      maxLines: null,
      padding: EdgeInsets.zero,
      decoration: null,
      placeholder: 'Start writing your note...',
      placeholderStyle: theme.textTheme.bodyLarge?.copyWith(
        color: colors.onSurfaceVariant.withValues(alpha: 0.50),
        height: 1.55,
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colors.onSurface,
        height: 1.55,
      ),
    );
  }
}
