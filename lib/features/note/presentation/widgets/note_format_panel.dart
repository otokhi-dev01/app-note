import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/core/theme/app_theme.dart';

class NoteFormatPanel extends StatelessWidget {
  final NoteDetailController controller;

  const NoteFormatPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = AppColors.isDark(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'note_editor_format_title'.tr,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryText,
                ),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 24,
                  color: colors.mutedIcon,
                ),
                onPressed: controller.toggleFormatPanel,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Style Selection (Title, Heading, etc.)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.cellFill,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StyleButton(
                  label: 'note_editor_style_title'.tr,
                  style: "title",
                  controller: controller,
                ),
                _StyleButton(
                  label: 'note_editor_style_heading'.tr,
                  style: "heading",
                  controller: controller,
                ),
                _StyleButton(
                  label: 'note_editor_style_subheading'.tr,
                  style: "subheading",
                  controller: controller,
                ),
                _StyleButton(
                  label: 'note_editor_style_body'.tr,
                  style: "body",
                  controller: controller,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Formatting Options Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconButton(
                icon: CupertinoIcons.bold,
                onTap: () => controller.applyInlineFormat(quill.Attribute.bold),
              ),
              _IconButton(
                icon: CupertinoIcons.italic,
                onTap: () =>
                    controller.applyInlineFormat(quill.Attribute.italic),
              ),
              _IconButton(
                icon: CupertinoIcons.underline,
                onTap: () =>
                    controller.applyInlineFormat(quill.Attribute.underline),
              ),
              _IconButton(
                icon: CupertinoIcons.strikethrough,
                onTap: () =>
                    controller.applyInlineFormat(quill.Attribute.strikeThrough),
              ),
              _IconButton(
                icon: Icons.edit_note_rounded,
                onTap: () => controller.applyHighlight(Colors.purpleAccent),
              ),
              _ColorCircle(
                color: Colors.purpleAccent,
                onTap: () => controller.applyHighlight(Colors.purpleAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Formatting Options Row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconButton(
                icon: Icons.format_list_bulleted_rounded,
                onTap: () => controller.applyInlineFormat(quill.Attribute.ul),
              ),
              _IconButton(
                icon: Icons.list_alt_rounded,
                onTap: () =>
                    controller.applyInlineFormat(quill.Attribute.unchecked),
              ),
              _IconButton(
                icon: Icons.format_list_numbered_rounded,
                onTap: () => controller.applyInlineFormat(quill.Attribute.ol),
              ),
              _IconButton(
                icon: Icons.format_align_left_rounded,
                onTap: () =>
                    controller.applyInlineFormat(quill.Attribute.leftAlignment),
              ),
              _IconButton(
                icon: Icons.format_indent_increase_rounded,
                onTap: controller.applyIndent,
              ),
              _IconButton(
                icon: Icons.view_column_rounded,
                onTap: controller.addTableBlock,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StyleButton extends StatelessWidget {
  final String label;
  final String style;
  final NoteDetailController controller;

  const _StyleButton({
    required this.label,
    required this.style,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        final isSelected = controller.currentBlockStyle.value == style;
        final colors = AppColors.of(context);

        return GestureDetector(
          onTap: () => controller.updateActiveBlockStyle(style),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.folderYellow : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isSelected
                    ? AppColors.onAccent(AppTheme.folderYellow)
                    : colors.primaryText,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 44,
        decoration: BoxDecoration(
          color: colors.cellFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: colors.primaryText),
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorCircle({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 44,
        alignment: Alignment.center,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
