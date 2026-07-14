import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class DrawingCanvas extends StatelessWidget {
  final double width;
  final double height;
  final Color selectedColor;
  final double strokeWidth;
  final Function(List<DrawingPoint?>) onDrawingChanged;
  final List<DrawingPoint?> initialPoints;

  const DrawingCanvas({
    super.key,
    required this.width,
    required this.height,
    required this.selectedColor,
    required this.strokeWidth,
    required this.onDrawingChanged,
    this.initialPoints = const [],
  });

  @override
  Widget build(BuildContext context) {
    // We use a local RxList to track the points locally while drawing
    // and sync it back via onDrawingChanged.
    final points = RxList<DrawingPoint?>(initialPoints);

    return GestureDetector(
      onPanUpdate: (details) {
        RenderBox renderBox = context.findRenderObject() as RenderBox;
        points.add(DrawingPoint(
          offset: renderBox.globalToLocal(details.globalPosition),
          paint: Paint()
            ..color = selectedColor
            ..strokeCap = StrokeCap.round
            ..strokeWidth = strokeWidth
            ..isAntiAlias = true,
        ));
        onDrawingChanged(points.toList());
      },
      onPanStart: (details) {
        RenderBox renderBox = context.findRenderObject() as RenderBox;
        points.add(DrawingPoint(
          offset: renderBox.globalToLocal(details.globalPosition),
          paint: Paint()
            ..color = selectedColor
            ..strokeCap = StrokeCap.round
            ..strokeWidth = strokeWidth
            ..isAntiAlias = true,
        ));
        onDrawingChanged(points.toList());
      },
      onPanEnd: (details) {
        points.add(null);
        onDrawingChanged(points.toList());
      },
      child: Obx(() => CustomPaint(
        size: Size(width, height),
        painter: MyPainter(points: points.toList()),
      )),
    );
  }
}

class MyPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  MyPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!.offset, points[i + 1]!.offset, points[i]!.paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(PointMode.points, [points[i]!.offset], points[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
