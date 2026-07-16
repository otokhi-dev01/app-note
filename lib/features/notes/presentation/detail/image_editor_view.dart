import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/core/presentation/images/image_helper.dart';
import 'package:notes/features/notes/presentation/attachments/controllers/image_editor_controller.dart';
import 'package:notes/features/notes/presentation/attachments/drawing_canvas.dart';
import 'package:notes/features/notes/presentation/attachments/widgets/drawing_editor_navigation_bar.dart';
import 'package:notes/features/notes/presentation/attachments/widgets/drawing_editor_toolbar.dart';
import 'package:notes/features/notes/presentation/home/home_style.dart';
import 'package:screenshot/screenshot.dart';

export 'package:notes/features/notes/presentation/attachments/controllers/image_editor_controller.dart';

class ImageEditorView extends StatefulWidget {
  const ImageEditorView({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<ImageEditorView> createState() => _ImageEditorViewState();
}

class _ImageEditorViewState extends State<ImageEditorView> {
  late final ImageEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImageEditorController(widget.imagePath);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: style.background,
      appBar: DrawingEditorNavigationBar(
        title: 'Markup',
        onCancel: Get.back,
        onDone: _controller.saveImage,
      ),
      body: ColoredBox(
        color: scheme.surfaceContainerLow,
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF111113),
                  border: Border(
                    bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: .55),
                      width: .5,
                    ),
                  ),
                ),
                child: Center(
                  child: Screenshot(
                    controller: _controller.screenshotController,
                    child: Stack(
                      children: [
                        ImageHelper.buildSafeImage(
                          widget.imagePath,
                          fit: BoxFit.contain,
                          radius: 0,
                        ),
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Obx(
                                () => DrawingCanvas(
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  selectedColor:
                                      _controller.selectedColor.value,
                                  strokeWidth: _controller.strokeWidth.value,
                                  initialPoints: _controller.points.toList(),
                                  onDrawingChanged:
                                      _controller.points.assignAll,
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
            DrawingEditorToolbar(
              controller: _controller,
              style: style,
              showTopBorder: true,
            ),
          ],
        ),
      ),
    );
  }
}
