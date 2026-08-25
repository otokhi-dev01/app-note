import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class SlidableNoteTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onMove;

  /// When null, the Delete swipe action is hidden entirely.
  final VoidCallback? onDelete;

  const SlidableNoteTile({
    super.key,
    required this.child,
    required this.onMove,
    this.onDelete,
  });

  @override
  State<SlidableNoteTile> createState() => _SlidableNoteTileState();
}

class _SlidableNoteTileState extends State<SlidableNoteTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  static const double _actionWidth = 80;

  /// Width of the revealed action strip, which shrinks when Delete is hidden.
  double get _totalActionsWidth =>
      _actionWidth * (widget.onDelete != null ? 2 : 1);

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
      if (_dragExtent < -_totalActionsWidth - 20) {
        _dragExtent = -_totalActionsWidth - 20; // Limit left drag
      }
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
    final animation = Tween<double>(
      begin: _dragExtent,
      end: -_totalActionsWidth,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    animation.addListener(() {
      setState(() => _dragExtent = animation.value);
    });
    _controller.forward(from: 0);
  }

  void _closeActions() {
    final animation = Tween<double>(
      begin: _dragExtent,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
                    "trash_move".tr,
                    CupertinoIcons.folder_fill,
                    const Color(0xFF5856D6),
                    widget.onMove,
                  ),
                  if (widget.onDelete != null)
                    _buildActionButton(
                      "trash_delete".tr,
                      CupertinoIcons.trash_fill,
                      const Color(0xFFFF3B30),
                      widget.onDelete!,
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        _closeActions();
        onTap();
      },
      child: Container(
        width: _actionWidth,
        height: double.infinity,
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double h = constraints.maxHeight;
            if (h < 5) return const SizedBox.shrink();

            // Super Safe: Scale down if space is tight
            // h=57 is your current constraint.
            // iconSize=24, space=2, text=12 => total ~38px. Should fit 57px easily.
            final bool showLabel = h > 55;
            final double iconSize = h > 65 ? 30 : (h > 45 ? 24 : 20);

            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomGlassContainer(
                        width: iconSize,
                        height: iconSize,
                        shape: GlassShape.circle,
                        blur: 10,
                        opacity: 0.16,
                        thickness: 5,
                        refractiveIndex: 1.1,
                        glassColor: color.withValues(alpha: 0.22),
                        alignment: Alignment.center,
                        child: Icon(icon, color: color, size: iconSize * 0.6),
                      ),
                      if (showLabel) ...[
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
