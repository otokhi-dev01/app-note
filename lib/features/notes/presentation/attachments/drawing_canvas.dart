import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DrawingPoint {
  const DrawingPoint({required this.offset, required this.paint});

  final Offset offset;
  final Paint paint;
}

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.width,
    required this.height,
    required this.selectedColor,
    required this.strokeWidth,
    required this.onDrawingChanged,
    this.initialPoints = const [],
  });

  final double width;
  final double height;
  final Color selectedColor;
  final double strokeWidth;
  final ValueChanged<List<DrawingPoint?>> onDrawingChanged;
  final List<DrawingPoint?> initialPoints;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late List<DrawingPoint?> _points;

  @override
  void initState() {
    super.initState();
    _points = List<DrawingPoint?>.of(widget.initialPoints);
  }

  @override
  void didUpdateWidget(covariant DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(_points, widget.initialPoints)) {
      _points = List<DrawingPoint?>.of(widget.initialPoints);
    }
  }

  void _addPoint(BuildContext context, Offset globalPosition) {
    final renderBox = context.findRenderObject()! as RenderBox;
    final point = DrawingPoint(
      offset: renderBox.globalToLocal(globalPosition),
      paint: Paint()
        ..color = widget.selectedColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = widget.strokeWidth
        ..isAntiAlias = true,
    );
    setState(() => _points.add(point));
    widget.onDrawingChanged(List<DrawingPoint?>.of(_points));
  }

  void _endStroke() {
    setState(() => _points.add(null));
    widget.onDrawingChanged(List<DrawingPoint?>.of(_points));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _addPoint(context, details.globalPosition),
      onPanUpdate: (details) => _addPoint(context, details.globalPosition),
      onPanEnd: (_) => _endStroke(),
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        painter: MyPainter(points: List<DrawingPoint?>.of(_points)),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  const MyPainter({required this.points});

  final List<DrawingPoint?> points;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(PointMode.points, [
          points[i]!.offset,
        ], points[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) => true;
}

typedef DrawingPainter = MyPainter;
