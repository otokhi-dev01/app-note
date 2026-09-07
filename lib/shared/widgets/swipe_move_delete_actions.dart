import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Wraps a list row (a folder tile in the note list's "Folders" section, a
/// note tile in its date groups, etc.) so dragging it left reveals "Move"
/// and "Delete" pill buttons anchored to the right edge.
///
/// Unlike [SlidableNoteTile] (trash), this doesn't mask the actions behind
/// an opaque foreground — it clips them to zero width at rest and grows
/// them in step with the drag. That keeps [child] exactly as transparent as
/// it was before, so it still blends into the shared [GlassCard] blur the
/// row lives in until the user actually swipes.
class SwipeMoveDeleteActions extends StatefulWidget {
  final Widget child;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const SwipeMoveDeleteActions({
    super.key,
    required this.child,
    required this.onMove,
    required this.onDelete,
  });

  @override
  State<SwipeMoveDeleteActions> createState() =>
      _SwipeMoveDeleteActionsState();
}

class _SwipeMoveDeleteActionsState extends State<SwipeMoveDeleteActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  double _dragExtent = 0;

  static const double actionWidth = 88;
  static const double _gap = 8;
  static const double _edgeGap = 12;
  static const double _totalActionsWidth = _edgeGap + actionWidth * 2 + _gap;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      if (_dragExtent > 0) _dragExtent = 0; // Prevent dragging to the right
      if (_dragExtent < -_totalActionsWidth) {
        _dragExtent = -_totalActionsWidth; // Limit left drag
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent < -_totalActionsWidth / 2) {
      _animateTo(-_totalActionsWidth);
    } else {
      _animateTo(0);
    }
  }

  void _animateTo(double target) {
    final animation = Tween<double>(begin: _dragExtent, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    void listener() => setState(() => _dragExtent = animation.value);
    animation.addListener(listener);
    _controller
      ..reset()
      ..forward().whenCompleteOrCancel(() {
        animation.removeListener(listener);
      });
  }

  void _close() => _animateTo(0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    right: -_totalActionsWidth - _dragExtent,
                    top: 0,
                    bottom: 0,
                    width: _totalActionsWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(right: _edgeGap),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ActionPill(
                            label: 'note_list_move'.tr,
                            icon: CupertinoIcons.folder_fill,
                            color: const Color(0xFF5856D6),
                            onTap: () {
                              _close();
                              widget.onMove();
                            },
                          ),
                          const SizedBox(width: _gap),
                          _ActionPill(
                            label: 'note_list_delete'.tr,
                            icon: CupertinoIcons.trash_fill,
                            color: const Color(0xFFFF3B30),
                            onTap: () {
                              _close();
                              widget.onDelete();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _SwipeMoveDeleteActionsState.actionWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
