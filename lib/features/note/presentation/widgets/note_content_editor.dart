import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_attachment_block.dart';
import 'package:Note/features/note/presentation/widgets/note_checklist_block.dart';
import 'package:Note/features/note/presentation/widgets/note_editor_header.dart';
import 'package:Note/features/note/presentation/widgets/note_editor_top_bar.dart';
import 'package:Note/features/note/presentation/widgets/note_scroll_utils.dart';
import 'package:Note/features/note/presentation/widgets/note_table_block.dart';
import 'package:Note/features/note/presentation/widgets/interactive_drawing_canvas.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class NoteContentEditor extends StatelessWidget {
  final NoteDetailController controller;

  const NoteContentEditor({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontalInset = _editorInset(context);
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 140;

    return Stack(
      children: [
        _PageContent(
          // Same scroll architecture as the rest of the app (Folder,
          // Recently Deleted, Note List): a CustomScrollView whose app bar
          // is a sliver that scrolls with the content instead of floating
          // as a separately-positioned fixed overlay.
          child: Obx(() {
            final isLoading = controller.isLoading.value;
            final isReadOnly = controller.isReadOnly.value;

            // BUG FIX: Gracefully handle null note during deletion cleanup
            final note = controller.currentNote.value;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // iOS Notes lets you scroll the note up and down while typing
              // without the keyboard dropping — dismissing on drag would
              // fight the cursor-follows-keyboard behavior above.
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              slivers: [
                NoteEditorTopBar(controller: controller),
                if (isReadOnly)
                  SliverToBoxAdapter(child: _buildReadOnlyBanner(context)),
                if (isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalInset,
                      16,
                      horizontalInset,
                      bottomPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        NoteEditorHeader(controller: controller),
                        const SizedBox(height: 16),
                        TextField(
                          key: const ValueKey('note-title-field'),
                          controller: controller.titleController,
                          focusNode: controller.titleFocusNode,
                          enabled: !isReadOnly,
                          // iOS Notes opens a brand-new note with the cursor
                          // already blinking and the keyboard up, ready to
                          // type — match that instead of requiring an extra
                          // tap to focus in.
                          autofocus: !isReadOnly && note?.id == 0,
                          onTap: () => controller.activeBlockIndex.value = -1,
                          cursorColor: AppTheme.folderYellow,
                          cursorWidth: 1.5,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => controller.focusFirstTextBlock(),
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'note_editor_title_hint'.tr,
                            hintStyle: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: 32,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
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
                          (entry) =>
                              _buildBlock(context, entry.value, entry.key),
                        ),
                      ]),
                    ),
                  ),
                // iOS-Notes-style "tap anywhere to keep typing": fills
                // whatever viewport space is left below the content, however
                // little or much that is, rather than only catching taps in
                // a fixed-height strip that leaves the rest of a short
                // note's blank space dead.
                if (!isReadOnly && !isLoading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: false,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: controller.focusLastTextBlock,
                      child: const SizedBox(width: double.infinity),
                    ),
                  ),
              ],
            );
          }),
        ),
        // Search Bar Overlay
        Obx(() {
          final searchTopPadding = MediaQuery.paddingOf(context).top + 60;
          return controller.isSearchVisible.value
              ? _buildSearchBar(context, searchTopPadding)
              : const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildReadOnlyBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'note_editor_readonly_banner_message'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              AppSnackbar.warning(
                'note_editor_readonly_tip_title'.tr,
                'note_editor_readonly_tip_message'.tr,
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'note_editor_ok'.tr,
              style: TextStyle(
                color: Colors.orange[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
                  decoration: InputDecoration(
                    hintText: 'note_editor_search_hint'.tr,
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
        child: GestureDetector(
          // Same long-press-to-delete pattern as attachment images, so a
          // drawing can be removed like any other block.
          onLongPress: () => _showDeleteDrawingMenu(context, blockIndex),
          child: Stack(
            children: [
              InteractiveDrawingCanvas(
                key: ValueKey('drawing-${block.id}'),
                onSave: (path) => controller.updateDrawing(blockIndex, path),
              ),
              // Direct delete button, matching the one on image/file
              // attachments — same reasoning: don't make removal depend on
              // finding the long-press menu first.
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

    // Set readOnly on the controller for flutter_quill 10+
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
          child: quill.QuillEditor.basic(
            controller: quillController,
            focusNode: focusNode,
            config: quill.QuillEditorConfig(
              customStyles: _paragraphStylesFor(context, block.style),
            ),
          ),
        ),
      ),
    );
  }

  /// Renders a block at the size/weight its Format-panel style implies
  /// ("Title", "Heading", "Subheading", "Body") — previously `block.style`
  /// was only used to highlight the selected button, with no visual effect
  /// on the block itself.
  quill.DefaultStyles _paragraphStylesFor(BuildContext context, String style) {
    final base = Theme.of(context).textTheme.bodyLarge!;
    final textStyle = switch (style) {
      'title' => base.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
      'heading' => base.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      'subheading' => base.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      _ => base.copyWith(fontSize: 17, fontWeight: FontWeight.normal),
    };
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
