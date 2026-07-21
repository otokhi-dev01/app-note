part of '../../view/create_note_view.dart';

class _DocumentRow extends StatelessWidget {
  final NoteDraftDocument document;
  final bool enabled;
  final VoidCallback onRemove;

  const _DocumentRow({
    required this.document,
    required this.enabled,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final String name = document.displayName.trim().isEmpty
        ? 'Document'
        : document.displayName.trim();

    final String extension = name.contains('.')
        ? name.split('.').last.toUpperCase()
        : 'FILE';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
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
            child: Icon(
              CupertinoIcons.doc_fill,
              size: 20,
              color: colors.primary,
            ),
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
                const SizedBox(height: 3),
                Text(
                  extension,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              pressedOpacity: 0.45,
              onPressed: enabled ? onRemove : null,
              child: Icon(
                CupertinoIcons.xmark_circle,
                size: 20,
                color: enabled
                    ? colors.onSurfaceVariant
                    : colors.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
