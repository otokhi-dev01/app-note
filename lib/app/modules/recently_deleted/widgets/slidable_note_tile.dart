import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../widgets/glass_widgets.dart';

class SlidableNoteTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const SlidableNoteTile({
    super.key,
    required this.child,
    required this.onMove,
    required this.onDelete,
  });

  @override
  State<SlidableNoteTile> createState() => _SlidableNoteTileState();
}

class _SlidableNoteTileState extends State<SlidableNoteTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  static const double _actionWidth = 80;
  static const double _totalActionsWidth = _actionWidth * 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      if (_dragExtent > 0) _dragExtent = 0; // Prevent dragging to the right
      if (_dragExtent < -_totalActionsWidth - 20) _dragExtent = -_totalActionsWidth - 20; // Limit left drag
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent < -_totalActionsWidth / 2) {
      _openActions();
    } else {
      _closeActions();
    }
  }

  void _openActions() {
    final animation = Tween<double>(begin: _dragExtent, end: -_totalActionsWidth).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    animation.addListener(() {
      setState(() => _dragExtent = animation.value);
    });
    _controller.forward(from: 0);
  }

  void _closeActions() {
    final animation = Tween<double>(begin: _dragExtent, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    animation.addListener(() {
      setState(() => _dragExtent = animation.value);
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          // Background Actions
          Positioned.fill(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    "Move",
                    CupertinoIcons.folder_fill,
                    const Color(0xFF5856D6),
                    widget.onMove,
                  ),
                  _buildActionButton(
                    "Delete",
                    CupertinoIcons.trash_fill,
                    const Color(0xFFFF3B30),
                    widget.onDelete,
                  ),
                ],
              ),
            ),
          ),
          
          // Foreground Content
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: Material(
              color: theme.colorScheme.surface,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        _closeActions();
        onTap();
      },
      child: Container(
        width: _actionWidth,
        height: double.infinity,
        color: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LiquidGlassContainer(
                width: 44,
                height: 44,
                borderRadius: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
