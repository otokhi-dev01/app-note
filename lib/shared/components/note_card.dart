import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notes/core/utils/image_helper.dart';
import 'package:notes/core/utils/date_formatter.dart';
import 'package:notes/data/models/note_model.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    this.onShare,
    this.onMove,
    this.onPin,
    this.isLast = false,
    this.subtitle,
  });

  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onMove;
  final VoidCallback? onPin;
  final bool isLast;
  final Widget? subtitle;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 72;
  late final AnimationController _animationController;

  int get _actionCount {
    var count = 1;
    if (widget.onShare != null) count++;
    if (widget.onMove != null) count++;
    if (widget.onPin != null) count++;
    return count;
  }

  double get _revealWidth => _actionCount * _actionWidth;
  bool get _isOpened => _animationController.value > 0.1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final horizontalDelta = details.primaryDelta ?? 0;
    final newValue =
        _animationController.value - (horizontalDelta / _revealWidth);
    _animationController.value = newValue.clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity < -450) {
      _openActions();
    } else if (velocity > 450) {
      _closeActions();
    } else if (_animationController.value >= 0.42) {
      _openActions();
    } else {
      _closeActions();
    }
  }

  void _openActions() {
    HapticFeedback.selectionClick();
    _animationController.animateTo(1, curve: Curves.easeOutCubic);
  }

  void _closeActions() {
    _animationController.animateBack(0, curve: Curves.easeOutCubic);
  }

  void _executeAction(VoidCallback callback) {
    HapticFeedback.lightImpact();
    _closeActions();
    callback();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final note = widget.note;
    final actions = [
      if (widget.onPin != null)
        _SwipeAction(
          width: _actionWidth,
          icon: note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
          label: 'Pin',
          color: const Color(0xFFFF9F0A),
          onPressed: () => _executeAction(widget.onPin!),
        ),
      if (widget.onShare != null)
        _SwipeAction(
          width: _actionWidth,
          icon: CupertinoIcons.share,
          label: 'Share',
          color: const Color(0xFF007AFF),
          onPressed: () => _executeAction(widget.onShare!),
        ),
      if (widget.onMove != null)
        _SwipeAction(
          width: _actionWidth,
          icon: CupertinoIcons.folder,
          label: 'Move',
          color: const Color(0xFF5856D6),
          onPressed: () => _executeAction(widget.onMove!),
        ),
      _SwipeAction(
        width: _actionWidth,
        icon: CupertinoIcons.trash,
        label: 'Delete',
        color: const Color(0xFFFF3B30),
        onPressed: () => _executeAction(widget.onDelete),
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 0.5),
      child: ClipRRect(
        child: GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: isDark
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFFF2F2F7),
                  alignment: Alignment.centerRight,
                  child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                ),
              ),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(-_animationController.value * _revealWidth, 0),
                  child: child,
                ),
                child: Material(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  child: InkWell(
                    onTap: () => _isOpened ? _closeActions() : widget.onTap(),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title.isEmpty
                                          ? 'Untitled'
                                          : note.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    widget.subtitle ??
                                        Row(
                                          children: [
                                            Text(
                                              DateFormatter.format(
                                                note.updatedAt,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                note.content.isEmpty
                                                    ? 'No additional text'
                                                    : note.content,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  ],
                                ),
                              ),
                              if (note.imagePaths.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                ImageHelper.buildSafeImage(
                                  note.imagePaths.first,
                                  width: 44,
                                  height: 44,
                                  radius: 6,
                                ),
                              ],
                              const SizedBox(width: 4),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                        if (!widget.isLast)
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Divider(
                              height: 0.5,
                              color: Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.width,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final double width;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      color: color,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
