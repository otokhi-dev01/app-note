import 'package:flutter/material.dart';

class InteractiveDrawingCanvas extends StatefulWidget {
  final ValueChanged<String>? onSave;
  const InteractiveDrawingCanvas({super.key, this.onSave});
  @override
  State<InteractiveDrawingCanvas> createState() =>
      _InteractiveDrawingCanvasState();
}

class _InteractiveDrawingCanvasState extends State<InteractiveDrawingCanvas> {
  final List<Offset?> _points = [];
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) =>
                  setState(() => _points.add(details.localPosition)),
              onPanUpdate: (details) =>
                  setState(() => _points.add(details.localPosition)),
              onPanEnd: (_) => setState(() => _points.add(null)),
              child: CustomPaint(
                painter: _DrawingPainter(
                  points: _points,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => setState(_points.clear),
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  _DrawingPainter({required this.points, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..isAntiAlias = true;
    for (int index = 0; index < points.length - 1; index++) {
      final currentPoint = points[index];
      final nextPoint = points[index + 1];
      if (currentPoint != null && nextPoint != null) {
        canvas.drawLine(currentPoint, nextPoint, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
