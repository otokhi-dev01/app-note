import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:notes/features/notes/presentation/attachments/drawing_canvas.dart';
import 'package:screenshot/screenshot.dart';

abstract class DrawingEditorController extends GetxController {
  final screenshotController = ScreenshotController();
  final selectedColor = Colors.black.obs;
  final strokeWidth = 5.0.obs;
  final points = <DrawingPoint?>[].obs;

  void pickColor(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor.value,
            onColorChanged: (color) => selectedColor.value = color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void clearPoints() {
    points.clear();
  }

  void undoLastStroke() {
    if (points.isEmpty) return;

    points.removeLast();
    while (points.isNotEmpty && points.last != null) {
      points.removeLast();
    }
  }
}
