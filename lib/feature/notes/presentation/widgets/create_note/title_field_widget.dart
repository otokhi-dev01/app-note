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
      placeholder: 'Note Title',
      placeholderStyle: theme.textTheme.headlineMedium?.copyWith(
        color: colors.onSurface.withValues(alpha: 0.3),
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
      ),
      style: theme.textTheme.headlineMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
      ),
      onSubmitted: (_) {
        FocusScope.of(context).nextFocus();
      },
    );
  }
}
