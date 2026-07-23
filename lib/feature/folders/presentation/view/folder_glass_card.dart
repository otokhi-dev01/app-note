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

    final Color accentColor = _parseFolderColor(widget.folder.colorValue, colors.primary);

    return Listener(
      onPointerDown: _onTapDown,
      onPointerUp: _onTapUp,
      onPointerCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onMore,
                child: IntrinsicHeight(
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 6,
                        color: accentColor,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      _folderIcon(widget.folder.iconName),
                                      size: 26,
                                      color: accentColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    CupertinoIcons.chevron_forward,
                                    size: 16,
                                    color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(width: 4),
                                  _MoreButton(onPressed: widget.onMore),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Projects, meeting notes, planning.', // Placeholder as per plan
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: <Widget>[
                                  if (timestamp != null)
                                    Text(
                                      'Updated ${_timeAgo(timestamp)}',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.onSurface.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${widget.folder.noteCount}',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime dateTime) {
  final Duration diff = DateTime.now().difference(dateTime);
  if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays >= 1) return '${diff.inDays}d ago';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'just now';
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

Color _parseFolderColor(String rawValue, Color fallback) {
  final String value = rawValue.trim();

  if (value.isEmpty || value.toLowerCase() == 'string') {
    return fallback;
  }

  try {
    String hex = value
        .replaceAll('#', '')
        .replaceAll('0x', '')
        .replaceAll('0X', '');

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return fallback;
    }

    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return fallback;
  }
}
