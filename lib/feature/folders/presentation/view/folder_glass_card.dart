part of 'folder_list_view.dart';

class _FolderGlassCard extends StatelessWidget {
  final FolderEntity folder;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _FolderGlassCard({
    super.key,
    required this.folder,
    required this.selected,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String name = folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();
    final DateTime? timestamp = folder.updatedAt ?? folder.createdAt;
    final Color tintColor = selected
        ? colors.primaryContainer.withValues(alpha: 0.72)
        : colors.surface.withValues(alpha: 0.68);

    return _GlassSurface(
      borderRadius: 23,
      padding: EdgeInsets.zero,
      tintColor: tintColor,
      borderColor: selected ? colors.primary.withValues(alpha: 0.32) : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(23),
          onTap: onTap,
          onLongPress: onMore,
          splashColor: colors.primary.withValues(alpha: 0.08),
          highlightColor: colors.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.primary
                            : colors.primaryContainer,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _folderIcon(folder.iconName),
                        size: 22,
                        color: selected
                            ? colors.onPrimary
                            : colors.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        pressedOpacity: 0.45,
                        onPressed: onMore,
                        child: Icon(
                          CupertinoIcons.ellipsis_circle,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${folder.noteCount} '
                        '${folder.noteCount == 1 ? 'note' : 'notes'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: selected
                              ? colors.onPrimaryContainer.withValues(
                                  alpha: 0.70,
                                )
                              : colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        _friendlyDate(timestamp.toLocal()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: selected
                              ? colors.onPrimaryContainer.withValues(
                                  alpha: 0.65,
                                )
                              : colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _folderIcon(String value) {
  switch (value.trim().toLowerCase()) {
    case 'work':
    case 'briefcase':
    case 'business':
      return CupertinoIcons.briefcase_fill;
    case 'school':
    case 'education':
      return CupertinoIcons.book_fill;
    case 'personal':
    case 'person':
      return CupertinoIcons.person_fill;
    case 'favorite':
    case 'heart':
      return CupertinoIcons.heart_fill;
    case 'travel':
    case 'flight':
      return CupertinoIcons.airplane;
    case 'home':
      return CupertinoIcons.house_fill;
    case 'code':
      return CupertinoIcons.device_laptop;
    case 'shopping':
      return CupertinoIcons.cart_fill;
    case 'photo':
    case 'photos':
      return CupertinoIcons.photo_fill;
    case 'music':
      return CupertinoIcons.music_note_2;
    case 'idea':
      return CupertinoIcons.lightbulb_fill;
    default:
      return CupertinoIcons.folder_fill;
  }
}

String _friendlyDate(DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime target = DateTime(date.year, date.month, date.day);
  final int difference = today.difference(target).inDays;

  if (difference == 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }
  if (difference > 1 && difference < 7) {
    return '${difference}d ago';
  }

  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}';
}
