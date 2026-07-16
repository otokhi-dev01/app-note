import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:notes/app/theme/colors.dart';
import '../../../shared/components/drawing_canvas.dart';
import '../home/home_style.dart';

class ImageEditorController extends GetxController {
  final String imagePath;
  ImageEditorController(this.imagePath);

  final screenshotController = ScreenshotController();
  final selectedColor = Colors.black.obs;
  final strokeWidth = 5.0.obs;
  final points = <DrawingPoint?>[].obs;

  void pickColor(BuildContext context) {
    showDialog(
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
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  void clearPoints() {
    points.clear();
  }

  Future<void> saveImage() async {
    final Uint8List? imageBytes = await screenshotController.capture();
    if (imageBytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'edited_${p.basename(imagePath)}';
      final String filePath = p.join(directory.path, fileName);
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);
      Get.back(result: filePath);
    }
  }
}

class ImageEditorView extends StatelessWidget {
  final String imagePath;

  const ImageEditorView({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ImageEditorController(imagePath));
    final style = HomeStyle.of(context);

    return Scaffold(
      backgroundColor: style.background,
      appBar: AppBar(
        backgroundColor: style.background,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton(
          onPressed: () => Get.back(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.magenta, fontSize: 17),
          ),
        ),
        title: Text(
          'Markup',
          style: TextStyle(
            color: style.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: controller.saveImage,
            child: Text(
              'Done',
              style: TextStyle(
                color: AppColors.magenta,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: Screenshot(
                  controller: controller.screenshotController,
                  child: Stack(
                    children: [
                      Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Image could not be loaded',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Obx(
                              () => DrawingCanvas(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                selectedColor: controller.selectedColor.value,
                                strokeWidth: controller.strokeWidth.value,
                                initialPoints: controller.points.toList(),
                                onDrawingChanged: (newPoints) {
                                  controller.points.assignAll(newPoints);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildToolbar(context, controller, style),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    ImageEditorController controller,
    HomeStyle style,
  ) {
    return Container(
      color: style.secondarySurface,
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _ColorButton(color: Colors.white, controller: controller),
                _ColorButton(color: Colors.black, controller: controller),
                _ColorButton(color: Colors.grey, controller: controller),
                _ColorButton(color: Colors.red, controller: controller),
                _ColorButton(color: Colors.orange, controller: controller),
                _ColorButton(color: Colors.yellow, controller: controller),
                _ColorButton(color: Colors.green, controller: controller),
                _ColorButton(color: Colors.blue, controller: controller),
                _ColorButton(color: Colors.purple, controller: controller),
                _ColorButton(color: AppColors.magenta, controller: controller),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.color_filter,
                    color: style.primaryText,
                    size: 28,
                  ),
                  onPressed: () => controller.pickColor(context),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Obx(
                () => IconButton(
                  icon: Icon(
                    CupertinoIcons.pencil,
                    color: controller.strokeWidth.value < 10
                        ? AppColors.magenta
                        : style.primaryText,
                  ),
                  onPressed: () => controller.strokeWidth.value = 5.0,
                ),
              ),
              Obx(
                () => IconButton(
                  icon: Icon(
                    CupertinoIcons.paintbrush,
                    color: controller.strokeWidth.value >= 10
                        ? AppColors.magenta
                        : style.primaryText,
                  ),
                  onPressed: () => controller.strokeWidth.value = 15.0,
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.trash, color: Colors.red),
                onPressed: controller.clearPoints,
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.arrow_uturn_left,
                  color: style.primaryText,
                ),
                onPressed: () {
                  if (controller.points.isNotEmpty) {
                    controller.points.removeLast();
                    while (controller.points.isNotEmpty &&
                        controller.points.last != null) {
                      controller.points.removeLast();
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final ImageEditorController controller;
  const _ColorButton({required this.color, required this.controller});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Obx(
      () => GestureDetector(
        onTap: () => controller.selectedColor.value = color,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: controller.selectedColor.value == color
                  ? AppColors.magenta
                  : style.border,
              width: 2,
            ),
            boxShadow: [
              if (controller.selectedColor.value == color)
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
