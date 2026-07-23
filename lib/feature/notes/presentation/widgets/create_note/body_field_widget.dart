part of '../../view/create_note_view.dart';

class _BodyField extends GetView<CreateNoteController> {
  const _BodyField();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showImageSourceDialog(context, controller);
      },
      child: CupertinoTextField(
        controller: controller.statementController,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        minLines: 10,
        maxLines: null,
        padding: EdgeInsets.zero,
        decoration: null,
        placeholder: 'Start writing your thoughts here...',
        placeholderStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.35),
          height: 1.6,
          fontSize: 17,
        ),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
          height: 1.6,
          fontSize: 17,
        ),
      ),
    );
  }
}
