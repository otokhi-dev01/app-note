part of '../../view/note_editor_view.dart';

class _AttachmentsCard extends StatelessWidget {
  final NoteEditorController controller;
  final VoidCallback onAddAttachment;

  const _AttachmentsCard({
    required this.controller,
    required this.onAddAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    final List<Map<String, dynamic>> attachments = controller.attachmentBlocks;

    return AppSurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          _SectionTitleRow(
            icon: CupertinoIcons.paperclip,
            title: 'Attachments',
            subtitle: attachments.isEmpty
                ? 'Add a photo or document'
                : '${attachments.length} '
                      '${attachments.length == 1 ? 'file' : 'files'} attached',
            actionIcon: CupertinoIcons.add_circled_solid,
            actionTooltip: 'Add attachment',
            actionEnabled: controller.canEdit,
            onAction: onAddAttachment,
          ),

          if (attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),

            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.45),
            ),

            const SizedBox(height: 4),

            for (
              int index = 0;
              index < attachments.length;
              index++
            ) ...<Widget>[
              _AttachmentRow(block: attachments[index]),
              if (index < attachments.length - 1)
                Divider(
                  height: 1,
                  indent: 52,
                  color: colors.outlineVariant.withValues(alpha: 0.35),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
