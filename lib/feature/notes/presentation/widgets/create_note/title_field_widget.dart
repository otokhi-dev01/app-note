part of '../../view/create_note_view.dart';

class _TitleField extends GetView<CreateNoteController> {
  const _TitleField();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return CupertinoTextField(
      controller: controller.titleController,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      maxLength: 250,
      minLines: 1,
      maxLines: 3,
      padding: EdgeInsets.zero,
      decoration: null,
      placeholder: 'Title',
      placeholderStyle: theme.textTheme.headlineSmall?.copyWith(
        color: colors.onSurfaceVariant.withValues(alpha: 0.50),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.45,
      ),
      style: theme.textTheme.headlineSmall?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.45,
      ),
      onSubmitted: (_) {
        FocusScope.of(context).nextFocus();
      },
    );
  }
}
