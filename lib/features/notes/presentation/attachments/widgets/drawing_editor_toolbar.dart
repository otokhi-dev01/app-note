import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/features/notes/presentation/attachments/controllers/drawing_editor_controller.dart';
import 'package:notes/features/notes/presentation/home/home_style.dart';

class DrawingEditorToolbar extends StatelessWidget {
  const DrawingEditorToolbar({
    super.key,
    required this.controller,
    required this.style,
    this.showTopBorder = false,
  });

  final DrawingEditorController controller;
  final HomeStyle style;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: showTopBorder ? null : style.secondarySurface,
      decoration: showTopBorder
          ? BoxDecoration(
              color: style.secondarySurface,
              border: Border(top: BorderSide(color: style.border, width: 0.5)),
            )
          : null,
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _DrawingColorButton(
                  color: Colors.white,
                  controller: controller,
                  style: style,
                ),
                _DrawingColorButton(
                  color: Colors.black,
                  controller: controller,
                  style: style,
                ),
                _DrawingColorButton(
                  color: Colors.grey,
                  controller: controller,
                  style: style,
                ),
                _DrawingColorButton(
                  color: Colors.red,
                  controller: controller,
                  style: style,
                ),
                _DrawingColorButton(
                  color: Colors.orange,
                  controller: controller,
                  style: style,
                ),
                _DrawingColorButton(
                  color: Colors.yellow,
                  controller: controller,
                  style: style,
                ),
                _DrawingColorButton(
                  color: Colors.green,
                  controller: controller,
                  style: style,
                ),
                _DrawingColorButton(
                  color: Colors.blue,
                  controller: controller,
                  style: style,
                ),
                _DrawingColorButton(
                  color: Colors.purple,
                  controller: controller,
                  style: style,
                ),
                _DrawingColorButton(
                  color: AppColors.magenta,
                  controller: controller,
                  style: style,
                ),
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
          const SizedBox(height: 12),
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
                onPressed: controller.undoLastStroke,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawingColorButton extends StatelessWidget {
  const _DrawingColorButton({
    required this.color,
    required this.controller,
    required this.style,
  });

  final Color color;
  final DrawingEditorController controller;
  final HomeStyle style;

  @override
  Widget build(BuildContext context) {
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
