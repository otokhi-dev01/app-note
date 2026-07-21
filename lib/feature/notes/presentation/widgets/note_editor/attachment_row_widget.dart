part of '../../view/note_editor_view.dart';

class _AttachmentRow extends StatelessWidget {
  final Map<String, dynamic> block;

  const _AttachmentRow({required this.block});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    final String attachmentId =
        (block['attachmentId'] ?? block['AttachmentId'] ?? '').toString();

    final String name = _displayName(attachmentId);

    final String extension = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';

    final bool isImage = <String>{
      'png',
      'jpg',
      'jpeg',
      'gif',
      'webp',
      'heic',
    }.contains(extension);

    final bool isPdf = extension == 'pdf';

    final IconData icon = isImage
        ? CupertinoIcons.photo_fill
        : isPdf
        ? CupertinoIcons.doc_text_fill
        : CupertinoIcons.doc_fill;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: colors.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (attachmentId.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    'Attachment #$attachmentId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  String _displayName(String attachmentId) {
    for (final String key in <String>[
      'displayName',
      'DisplayName',
      'fileName',
      'FileName',
      'name',
      'Name',
    ]) {
      final String value = block[key]?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return attachmentId.trim().isEmpty
        ? 'Attached file'
        : 'Attachment $attachmentId';
  }
}
