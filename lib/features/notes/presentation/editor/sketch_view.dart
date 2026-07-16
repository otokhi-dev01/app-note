import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/features/notes/presentation/attachments/controllers/sketch_controller.dart';
import 'package:notes/features/notes/presentation/attachments/drawing_canvas.dart';
import 'package:notes/features/notes/presentation/attachments/widgets/drawing_editor_navigation_bar.dart';
import 'package:notes/features/notes/presentation/attachments/widgets/drawing_editor_toolbar.dart';
import 'package:notes/features/notes/presentation/home/home_style.dart';
import 'package:screenshot/screenshot.dart';

export 'package:notes/features/notes/presentation/attachments/controllers/sketch_controller.dart';

class SketchView extends StatefulWidget {
  const SketchView({super.key});

  @override
  State<SketchView> createState() => _SketchViewState();
}

class _SketchViewState extends State<SketchView> {
  late final SketchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SketchController();
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
        title: 'Sketch',
        onCancel: Get.back,
        onDone: _controller.saveSketch,
      ),
      body: ColoredBox(
        color: scheme.surfaceContainerLow,
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: .55),
                      width: .5,
                    ),
                  ),
                ),
                child: Screenshot(
                  controller: _controller.screenshotController,
                  child: ColoredBox(
                    // Keep exported sketches readable in every app theme.
                    color: Colors.white,
                    child: SizedBox.expand(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Obx(
                            () => DrawingCanvas(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              selectedColor: _controller.selectedColor.value,
                              strokeWidth: _controller.strokeWidth.value,
                              initialPoints: _controller.points.toList(),
                              onDrawingChanged: _controller.points.assignAll,
                            ),
                          );
                        },
                      ),
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
