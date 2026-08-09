import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../controllers/note_detail_controller.dart';
import '../../../theme/app_theme.dart';

class NoteFormatPanel extends StatelessWidget {
  final NoteDetailController controller;

  const NoteFormatPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
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
              const Text(
                "Format",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 24,
                  color: isDark ? Colors.white30 : Colors.black12,
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
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StyleButton(label: "Title", style: "title", controller: controller),
                _StyleButton(label: "Heading", style: "heading", controller: controller),
                _StyleButton(label: "Subheading", style: "subheading", controller: controller),
                _StyleButton(label: "Body", style: "body", controller: controller),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Formatting Options Row 1 (B I U S)
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FormatButton(
                label: "B",
                isBold: true,
                isSelected: controller.activeAttributes.containsKey(quill.Attribute.bold.key),
                onTap: () => controller.applyInlineFormat(quill.Attribute.bold),
              ),
              _FormatButton(
                label: "I",
                isItalic: true,
                isSelected: controller.activeAttributes.containsKey(quill.Attribute.italic.key),
                onTap: () => controller.applyInlineFormat(quill.Attribute.italic),
              ),
              _FormatButton(
                label: "U",
                isUnderline: true,
                isSelected: controller.activeAttributes.containsKey(quill.Attribute.underline.key),
                onTap: () => controller.applyInlineFormat(quill.Attribute.underline),
              ),
              _FormatButton(
                label: "S",
                isStrikethrough: true,
                isSelected: controller.activeAttributes.containsKey(quill.Attribute.strikeThrough.key),
                onTap: () => controller.applyInlineFormat(quill.Attribute.strikeThrough),
              ),
              _IconButton(
                icon: Icons.notes_rounded, // Similar to screenshot next to S
                isSelected: controller.activeAttributes[quill.Attribute.align.key] == 'center',
                onTap: () => controller.applyInlineFormat(quill.Attribute.centerAlignment),
              ),
              _ColorCircle(color: AppTheme.folderPink),
            ],
          )),
          const SizedBox(height: 12),
          // Formatting Options Row 2 (Lists, Alignments, etc.)
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconButton(
                icon: Icons.format_list_bulleted_rounded,
                isSelected: controller.activeAttributes[quill.Attribute.list.key] == 'bullet',
                onTap: () => controller.applyInlineFormat(quill.Attribute.ul),
              ),
              _IconButton(
                icon: Icons.checklist_rounded, // Checklist icon
                isSelected: controller.activeAttributes[quill.Attribute.list.key] == 'checked' || controller.activeAttributes[quill.Attribute.list.key] == 'unchecked',
                onTap: () => controller.applyInlineFormat(quill.Attribute.unchecked),
              ),
              _IconButton(
                icon: Icons.format_list_numbered_rounded,
                isSelected: controller.activeAttributes[quill.Attribute.list.key] == 'ordered',
                onTap: () => controller.applyInlineFormat(quill.Attribute.ol),
              ),
              _IconButton(
                icon: Icons.format_align_left_rounded,
                isSelected: controller.activeAttributes[quill.Attribute.align.key] == null || controller.activeAttributes[quill.Attribute.align.key] == 'left',
                onTap: () => controller.applyInlineFormat(quill.Attribute.leftAlignment),
              ),
              _IconButton(
                icon: Icons.format_indent_increase_rounded,
                isSelected: controller.activeAttributes.containsKey(quill.Attribute.indent.key),
                onTap: () => controller.applyInlineFormat(quill.Attribute.indent),
              ),
              _IconButton(
                icon: Icons.grid_view_rounded, // For table/columns
                isSelected: false,
                onTap: () => controller.addTableBlock(),
              ),
            ],
          )),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: () => controller.updateActiveBlockStyle(style),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.folderPink : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;

  const _FormatButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.folderPink 
              : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Serif',
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline 
                ? TextDecoration.underline 
                : (isStrikethrough ? TextDecoration.lineThrough : TextDecoration.none),
            color: isSelected 
                ? Colors.white 
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon, 
    required this.isSelected, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.folderPink 
              : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected 
              ? Colors.white 
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;

  const _ColorCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 44,
      alignment: Alignment.center,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
