part of '../../view/note_list_view.dart';

class _NoteRow extends StatefulWidget {
  final NoteEntity note;
  final String folderName;
  final Color folderColor;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _NoteRow({
    required this.note,
    required this.folderName,
    required this.folderColor,
    required this.onTap,
    required this.onMore,
  });

  @override
  State<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<_NoteRow> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
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

    final String title = widget.note.title.trim().isEmpty
        ? 'Untitled Note'
        : widget.note.title.trim();

    final DateTime? timestamp = widget.note.updatedAt ?? widget.note.createdAt;
    final int attachmentCount = _attachmentCount(widget.note);

    final Color cardColor = widget.note.isPinned
        ? colors.primaryContainer.withValues(alpha: isDark ? 0.45 : 0.65)
        : colors.surface.withValues(alpha: isDark ? 0.70 : 0.60);

    final Color borderColor = widget.note.isPinned
        ? colors.primary.withValues(alpha: 0.45)
        : colors.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.45);

    return Listener(
      onPointerDown: _onTapDown,
      onPointerUp: _onTapUp,
      onPointerCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AppGlassSurface(
          borderRadius: 24,
          padding: EdgeInsets.zero,
          tintColor: cardColor,
          borderColor: borderColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onMore,
              borderRadius: BorderRadius.circular(24),
              splashColor: colors.primary.withValues(alpha: 0.12),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _NoteIcon(
                      color: widget.folderColor,
                      locked: widget.note.isLocked,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              if (widget.note.isPinned)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    CupertinoIcons.pin_fill,
                                    size: 14,
                                    color: colors.primary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _notePreview(widget.note),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.85,
                              ),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _NoteMetadata(
                            folderName: widget.folderName,
                            folderColor: widget.folderColor,
                            locked: widget.note.isLocked,
                            attachmentCount: attachmentCount,
                            timestamp: timestamp,
                          ),
                        ],
                      ),
                    ),
                    _MoreButton(onPressed: widget.onMore),
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
        padding: const EdgeInsets.all(8),
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
