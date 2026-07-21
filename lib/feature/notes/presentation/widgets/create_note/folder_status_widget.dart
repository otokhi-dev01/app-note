part of '../../view/create_note_view.dart';

class _FolderStatus extends GetView<CreateNoteController> {
  final VoidCallback onPressed;

  const _FolderStatus({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Obx(() {
      final String folderName = controller.selectedFolderName.trim();

      final int attachmentCount =
          controller.selectedImages.length +
          controller.selectedDocuments.length;

      return AppSurfaceCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            splashColor: colors.primary.withValues(alpha: 0.08),
            highlightColor: colors.primary.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.folder_fill,
                      size: 19,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          folderName.isEmpty ? 'Choose Folder' : folderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          folderName.isEmpty
                              ? 'Select where this note will be saved'
                              : 'Tap to change folder',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (attachmentCount > 0) ...<Widget>[
                    Icon(
                      CupertinoIcons.paperclip,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      attachmentCount.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
