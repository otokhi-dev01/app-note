import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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

  static const double _maxContentWidth = 600;
  static const double _topBarControlSize = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteDate = controller.currentNote.value?.updatedAt ?? DateTime.now();
    final horizontalInset = _editorInset(context);
    final topPadding = MediaQuery.paddingOf(context).top + _topBarControlSize + 16;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 140; // Space for toolbar + buffer

    return Stack(
      children: [
        _PageContent(
          child: ListView(
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
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('note-title-field'),
                controller: controller.titleController,
                enabled: !controller.isReadOnly.value,
                onTap: () => controller.activeBlockIndex = -1,
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
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isCollapsed: true,
                  filled: false,
                  fillColor: Colors.transparent, // Explicitly transparent
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in controller.blocks.asMap().entries)
                _buildBlock(context, entry.value, entry.key),
            ],
          ),
        ),
        // Search Bar Overlay
        Obx(() => controller.isSearchVisible.value
            ? _buildSearchBar(context)
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top + 60; // Just below top bar

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        elevation: isDark ? 0 : 10,
        borderRadius: BorderRadius.circular(15),
        color: theme.colorScheme.surface,
        shape: isDark ? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: theme.dividerColor, width: 0.5),
        ) : null,
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
      return NoteChecklistBlock(block: block, blockIndex: blockIndex, controller: controller);
    }
    if (block is AttachmentBlock) {
      return NoteAttachmentBlock(block: block, blockIndex: blockIndex, controller: controller);
    }
    if (block is TableBlock) {
      return NoteTableBlock(block: block, blockIndex: blockIndex, controller: controller);
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

  Widget _buildTextBlock(BuildContext context, TextBlock block, int blockIndex) {
    final theme = Theme.of(context);
    final textController = controller.getTextController(block.id, block.text);
    final textStyle = _textBlockStyle(theme, block.style);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextField(
        key: ValueKey('note-text-${block.id}'),
        controller: textController,
        enabled: !controller.isReadOnly.value,
        onTap: () => controller.activeBlockIndex = blockIndex,
        onChanged: (value) => controller.updateTextBlock(blockIndex, value),
        cursorColor: AppTheme.folderYellow,
        cursorWidth: 1.5,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        scrollPadding: const EdgeInsets.only(bottom: 92),
        style: textStyle,
        decoration: InputDecoration(
          hintText: 'Start writing...',
          hintStyle: textStyle?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isCollapsed: true,
          filled: false,
          fillColor: Colors.transparent, // Explicitly transparent
        ),
      ),
    );
  }

  TextStyle? _textBlockStyle(ThemeData theme, String style) {
    switch (style) {
      case 'title':
        return theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold);
      case 'heading':
        return theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
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
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
