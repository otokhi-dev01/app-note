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
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ink color',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.35,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor.value,
              onColorChanged: (color) => selectedColor.value = color,
              pickerAreaBorderRadius: BorderRadius.circular(16),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(88, 44),
                shape: const StadiumBorder(),
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
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
