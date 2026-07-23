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
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                        color: widget.folderColor,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 10, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: widget.folderColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      widget.note.isLocked 
                                          ? CupertinoIcons.lock_fill 
                                          : CupertinoIcons.doc_text_fill,
                                      size: 20,
                                      color: widget.folderColor,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
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
                                        const SizedBox(height: 2),
                                        Text(
                                          _notePreview(widget.note),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _MoreButton(onPressed: widget.onMore),
                                ],
                              ),
                              const SizedBox(height: 16),
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
                                  if (attachmentCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.onSurface.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.paperclip,
                                            size: 12,
                                            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$attachmentCount',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              color: colors.onSurfaceVariant,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
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
