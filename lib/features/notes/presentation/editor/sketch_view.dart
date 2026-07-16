import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/features/notes/presentation/attachments/controllers/sketch_controller.dart';
import 'package:notes/features/notes/presentation/attachments/drawing_canvas.dart';
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

    return Scaffold(
      backgroundColor: style.background,
      appBar: AppBar(
        backgroundColor: style.background,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.magenta, fontSize: 17),
          ),
        ),
        title: Text(
          'Sketch',
          style: TextStyle(
            color: style.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _controller.saveSketch,
            child: const Text(
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
            child: Screenshot(
              controller: _controller.screenshotController,
              child: Container(
                // Keep exported sketches readable in every app theme.
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
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
          DrawingEditorToolbar(
            controller: _controller,
            style: style,
            showTopBorder: true,
          ),
        ],
      ),
    );
  }
}
