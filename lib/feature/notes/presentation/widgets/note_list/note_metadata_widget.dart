part of '../../view/note_list_view.dart';

class _NoteMetadata extends StatelessWidget {
  final String folderName;
  final Color folderColor;
  final bool locked;
  final int attachmentCount;
  final DateTime? timestamp;

  const _NoteMetadata({
    required this.folderName,
    required this.folderColor,
    required this.locked,
    required this.attachmentCount,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(CupertinoIcons.folder_fill, size: 13, color: folderColor),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  folderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (locked) ...<Widget>[
          const SizedBox(width: 9),
          Icon(
            CupertinoIcons.lock_fill,
            size: 13,
            color: colors.onSurfaceVariant,
          ),
        ],
        if (attachmentCount > 0) ...<Widget>[
          const SizedBox(width: 9),
          Icon(
            CupertinoIcons.paperclip,
            size: 14,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            attachmentCount.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        if (timestamp != null) ...<Widget>[
          const Spacer(),
          Text(
            _friendlyDate(timestamp!.toLocal()),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
