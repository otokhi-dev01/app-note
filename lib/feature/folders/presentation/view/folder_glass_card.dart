part of 'folder_list_view.dart';

class _FolderGlassCard extends StatefulWidget {
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
  State<_FolderGlassCard> createState() => _FolderGlassCardState();
}

class _FolderGlassCardState extends State<_FolderGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(PointerDownEvent event) => _pressController.forward();
  void _onTapUp(PointerUpEvent event) => _pressController.reverse();
  void _onTapCancel(PointerCancelEvent event) => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    final String name = widget.folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : widget.folder.name.trim();
    final DateTime? timestamp = widget.folder.updatedAt ?? widget.folder.createdAt;

    final Color cardColor = widget.selected
        ? colors.primaryContainer.withValues(alpha: isDark ? 0.45 : 0.65)
        : colors.surface.withValues(alpha: isDark ? 0.70 : 0.60);

    final Color borderColor = widget.selected
        ? colors.primary.withValues(alpha: 0.45)
        : colors.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.45);

    return Listener(
      onPointerDown: _onTapDown,
      onPointerUp: _onTapUp,
      onPointerCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _GlassSurface(
          borderRadius: 26,
          padding: EdgeInsets.zero,
          tintColor: cardColor,
          borderColor: borderColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: widget.onTap,
              onLongPress: widget.onMore,
              splashColor: colors.primary.withValues(alpha: 0.12),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.selected
                                ? colors.primary
                                : colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: widget.selected
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: colors.primary.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _folderIcon(widget.folder.iconName),
                            size: 24,
                            color: widget.selected
                                ? colors.onPrimary
                                : colors.primary,
                          ),
                        ),
                        const Spacer(),
                        _MoreButton(onPressed: widget.onMore),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${widget.folder.noteCount} '
                            '${widget.folder.noteCount == 1 ? 'note' : 'notes'}',
                            maxLines: 1,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (timestamp != null)
                          Text(
                            _friendlyDate(timestamp.toLocal()),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MoreButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.ellipsis,
          size: 18,
          color: colors.onSurfaceVariant,
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
