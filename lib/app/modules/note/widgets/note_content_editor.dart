import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../data/models/note_model.dart';
import '../../../theme/app_theme.dart';
import '../controllers/note_detail_controller.dart';
import 'note_attachment_block.dart';
import 'note_checklist_block.dart';
import 'note_table_block.dart';
import 'interactive_drawing_canvas.dart';

class NoteContentEditor extends StatelessWidget {
  final NoteDetailController controller;

  const NoteContentEditor({super.key, required this.controller});

  static const double _topBarControlSize = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontalInset = _editorInset(context);
    final baseTopPadding = MediaQuery.paddingOf(context).top + _topBarControlSize + 16;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 140;

    return Stack(
      children: [
        _PageContent(
          child: Obx(
            () {
              final isReadOnly = controller.isReadOnly.value;
              final topPadding = baseTopPadding + (isReadOnly ? 52 : 0);
              final noteDate = controller.currentNote.value?.updatedAt ?? DateTime.now();

              return ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  topPadding,
                  horizontalInset,
                  bottomPadding,
                ),
                children: [
                  Text(
                    DateFormat("MMMM d, yyyy 'at' h:mm a").format(noteDate),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('note-title-field'),
                    controller: controller.titleController,
                    enabled: !isReadOnly,
                    onTap: () => controller.activeBlockIndex.value = -1,
                    cursorColor: AppTheme.folderYellow,
                    cursorWidth: 1.5,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 32,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                      filled: false,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...controller.blocks.asMap().entries.map(
                    (entry) => _buildBlock(context, entry.value, entry.key),
                  ),
                ],
              );
            },
          ),
        ),
        // Search Bar Overlay
        Obx(
          () {
            final isReadOnly = controller.isReadOnly.value;
            final searchTopPadding = MediaQuery.paddingOf(context).top + 60 + (isReadOnly ? 52 : 0);
            return controller.isSearchVisible.value
                ? _buildSearchBar(context, searchTopPadding)
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, double topPadding) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        elevation: isDark ? 0 : 10,
        borderRadius: BorderRadius.circular(15),
        color: theme.colorScheme.surface,
        shape: isDark
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: theme.dividerColor, width: 0.5),
              )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(CupertinoIcons.search, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  focusNode: controller.searchFocusNode,
                  onChanged: (v) => controller.searchQuery.value = v,
                  decoration: const InputDecoration(
                    hintText: "Find in note...",
                    border: InputBorder.none,
                    isCollapsed: true,
                    filled: false,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 18),
                onPressed: controller.toggleSearch,
              ),
            ],
          ),
        ),
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
        child: InteractiveDrawingCanvas(
          key: ValueKey('drawing-${block.id}'),
          onSave: (path) => controller.updateDrawing(blockIndex, path),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTextBlock(
    BuildContext context,
    TextBlock block,
    int blockIndex,
  ) {
    final quillController = controller.getQuillController(block.id, block.text);
    final isReadOnly = controller.isReadOnly.value;
    
    // Set readOnly on the controller for flutter_quill 10+
    quillController.readOnly = isReadOnly;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            controller.activeBlockIndex.value = blockIndex;
            controller.currentBlockStyle.value = block.style;
          }
        },
        child: quill.QuillEditor.basic(
          controller: quillController,
        ),
      ),
    );
  }

  TextStyle? _textBlockStyle(ThemeData theme, String style) {
    switch (style) {
      case 'title':
        return theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        );
      case 'heading':
        return theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        );
      default:
        return theme.textTheme.bodyLarge?.copyWith(height: 1.45);
    }
  }

  double _editorInset(BuildContext context) {
    return (MediaQuery.sizeOf(context).width * 0.065).clamp(21.0, 32.0);
  }
}

class _PageContent extends StatelessWidget {
  final Widget child;
  const _PageContent({required this.child});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
