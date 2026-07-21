part of '../../view/create_note_view.dart';

class _ErrorMessage extends GetView<CreateNoteController> {
  const _ErrorMessage();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Obx(() {
      final String message = controller.errorMessage.value.trim();

      if (message.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.error.withValues(alpha: 0.16)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                size: 19,
                color: colors.error,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
