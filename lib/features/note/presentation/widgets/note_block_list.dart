import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:get/get.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_attachment_block.dart';
import 'package:Note/features/note/presentation/widgets/note_checklist_block.dart';
import 'package:Note/features/note/presentation/widgets/note_scroll_utils.dart';
import 'package:Note/features/note/presentation/widgets/note_table_block.dart';
import 'package:Note/features/note/presentation/widgets/interactive_drawing_canvas.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class NoteBlockList extends StatelessWidget {
  final NoteDetailController controller;

  final String? textPlaceholder;

  const NoteBlockList({
    super.key,
    required this.controller,
    this.textPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: controller.blocks
            .asMap()
            .entries
            .map((entry) => _buildBlock(context, entry.value, entry.key))
            .toList(),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, NoteBlock block, int blockIndex) {
    if (block is TextBlock) {
      return _buildTextBlock(context, block, blockIndex);
    }
    if (block is ChecklistBlock) {
      return NoteChecklistBlock(
        block: block,
        blockIndex: blockIndex,
        controller: controller,
      );
    }
    if (block is AttachmentBlock) {
      return NoteAttachmentBlock(
        key: block.id == controller.importedPdfBlockId
            ? controller.importedPdfPreviewKey
            : ValueKey('attachment-${block.id}'),
        block: block,
        blockIndex: blockIndex,
        controller: controller,
      );
    }
    if (block is TableBlock) {
      return NoteTableBlock(
        block: block,
        blockIndex: blockIndex,
        controller: controller,
      );
    }
    if (block is DrawingBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onLongPress: () => _showDeleteDrawingMenu(context, blockIndex),
          child: Stack(
            children: [
              InteractiveDrawingCanvas(
                key: ValueKey('drawing-${block.id}'),
                onSave: (path) => controller.updateDrawing(blockIndex, path),
              ),

              if (!controller.isReadOnly.value)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => controller.deleteBlock(blockIndex),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showDeleteDrawingMenu(BuildContext context, int blockIndex) {
    if (controller.isReadOnly.value) return;

    CustomGlassActionSheet.show(
      context: context,
      title: 'note_editor_drawing_options_title'.tr,
      actions: [
        CustomGlassActionSheetAction(
          label: 'note_editor_delete_drawing'.tr,
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onPressed: () => controller.deleteBlock(blockIndex),
        ),
      ],
    );
  }

  Widget _buildTextBlock(
    BuildContext context,
    TextBlock block,
    int blockIndex,
  ) {
    final quillController = controller.getQuillController(block.id, block.text);
    final focusNode = controller.getBlockFocusNode(block.id);
    final isReadOnly = controller.isReadOnly.value;

    quillController.readOnly = isReadOnly;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Builder(
        builder: (blockContext) => Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              controller.activeBlockIndex.value = blockIndex;
              controller.currentBlockStyle.value = block.style;
              ensureBlockVisible(blockContext);
            }
          },
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              if (textPlaceholder != null)
                AnimatedBuilder(
                  animation: quillController,
                  builder: (context, _) =>
                      controller.isTextBlockVisiblyEmpty(block.id)
                      ? IgnorePointer(
                          child: Text(
                            textPlaceholder!,
                            style: _textStyleFor(context, block.style).copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              quill.QuillEditor.basic(
                controller: quillController,
                focusNode: focusNode,
                config: quill.QuillEditorConfig(
                  scrollable: false,
                  scrollBottomInset: _keyboardClearance(context),
                  customStyles: _paragraphStylesFor(context, block.style),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  quill.DefaultStyles _paragraphStylesFor(BuildContext context, String style) {
    final textStyle = _textStyleFor(context, style);
    return quill.DefaultStyles(
      paragraph: quill.DefaultTextBlockStyle(
        textStyle,
        const quill.HorizontalSpacing(0, 0),
        const quill.VerticalSpacing(0, 0),
        const quill.VerticalSpacing(0, 0),
        null,
      ),
    );
  }

  TextStyle _textStyleFor(BuildContext context, String style) {
    final base = Theme.of(context).textTheme.bodyLarge!;
    return switch (style) {
      'title' => base.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
      'heading' => base.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      'subheading' => base.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      _ => base.copyWith(fontSize: 17, fontWeight: FontWeight.normal),
    };
  }

  double _keyboardClearance(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return keyboardHeight == 0 ? 0 : keyboardHeight + 72;
  }
}
