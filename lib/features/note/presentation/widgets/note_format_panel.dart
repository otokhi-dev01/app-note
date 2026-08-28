import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class NoteFormatPanel extends StatelessWidget {
  final NoteDetailController controller;

  const NoteFormatPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return CustomGlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      borderRadius: 28,
      blur: 35,
      opacity: 0.18,
      thickness: 10,
      showGlow: true,
      animateLiquid: true,
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
          _ScrollableFormatRow(
            children: [
              _IconButton(
                icon: CupertinoIcons.bold,
                semanticLabel: 'note_editor_bold_label'.tr,
                onTap: () => controller.applyInlineFormat(quill.Attribute.bold),
              ),
              _IconButton(
                icon: CupertinoIcons.italic,
                semanticLabel: 'note_editor_italic_label'.tr,
                onTap: () =>
                    controller.applyInlineFormat(quill.Attribute.italic),
              ),
              _IconButton(
                icon: CupertinoIcons.underline,
                semanticLabel: 'note_editor_underline_label'.tr,
                onTap: () =>
                    controller.applyInlineFormat(quill.Attribute.underline),
              ),
              _IconButton(
                icon: CupertinoIcons.strikethrough,
                semanticLabel: 'note_editor_strikethrough_label'.tr,
                onTap: () =>
                    controller.applyInlineFormat(quill.Attribute.strikeThrough),
              ),
              _IconButton(
                icon: CupertinoIcons.link,
                semanticLabel: 'note_editor_link_label'.tr,
                onTap: controller.addLink,
              ),
              _ColorCircle(
                color: Colors.purpleAccent,
                semanticLabel: 'note_editor_highlight_label'.tr,
                onTap: () => controller.applyHighlight(Colors.purpleAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Formatting Options Row 2
          _ScrollableFormatRow(
            children: [
              _IconButton(
                icon: Icons.format_list_bulleted_rounded,
                semanticLabel: 'note_editor_bullet_list_label'.tr,
                onTap: () => controller.applyInlineFormat(quill.Attribute.ul),
              ),
              _IconButton(
                icon: Icons.list_alt_rounded,
                semanticLabel: 'note_editor_checklist_label'.tr,
                onTap: () =>
                    controller.applyInlineFormat(quill.Attribute.unchecked),
              ),
              _IconButton(
                icon: Icons.format_list_numbered_rounded,
                semanticLabel: 'note_editor_numbered_list_label'.tr,
                onTap: () => controller.applyInlineFormat(quill.Attribute.ol),
              ),
              _IconButton(
                icon: Icons.format_align_left_rounded,
                semanticLabel: 'note_editor_align_left_label'.tr,
                onTap: () =>
                    controller.applyInlineFormat(quill.Attribute.leftAlignment),
              ),
              _IconButton(
                icon: Icons.format_indent_increase_rounded,
                semanticLabel: 'note_editor_indent_label'.tr,
                onTap: controller.applyIndent,
              ),
              _IconButton(
                icon: Icons.view_column_rounded,
                semanticLabel: 'note_editor_table_label'.tr,
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
  final String semanticLabel;

  const _IconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
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
      ),
    );
  }
}

class _ScrollableFormatRow extends StatelessWidget {
  final List<Widget> children;

  const _ScrollableFormatRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final String semanticLabel;

  const _ColorCircle({
    required this.color,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
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
      ),
    );
  }
}
