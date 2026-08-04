import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/models/note_model.dart';
import '../../widgets/glass_widgets.dart';
import 'note_detail_controller.dart';
import '../../theme/app_theme.dart';

class NoteDetailView extends GetView<NoteDetailController> {
  const NoteDetailView({super.key});

  static const double _maxContentWidth = 600;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // Sticky Top Bar with Background (covers status bar)
            _buildTopBar(context),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                    ),
                  );
                }
        
                return Stack(
                  children: [
                    _buildEditor(context),
                    // The toolbar is now positioned relative to the keyboard
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildEditingToolbar(context),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final controlSize = 40.0;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(top: topPadding),
      child: _pageContent(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: controlSize,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Back button
                LiquidGlassContainer(
                  width: 44,
                  height: 44,
                  borderRadius: 22,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: Get.back,
                    icon: const Icon(
                      CupertinoIcons.chevron_left,
                      color: AppTheme.textSecondary,
                      size: 28,
                    ),
                  ),
                ),

                // Right Actions: Undo, Share, More, Done
                Row(
                  children: [
                    _topBarIcon(context, CupertinoIcons.arrow_uturn_left, onTap: () {}),
                    const SizedBox(width: 12),
                    _topBarIcon(context, CupertinoIcons.share, onTap: () {}),
                    const SizedBox(width: 12),
                    _topBarIcon(context, CupertinoIcons.ellipsis_circle, onTap: () {}),
                    const SizedBox(width: 12),
                    LiquidGlassContainer(
                      width: 40,
                      height: 40,
                      borderRadius: 20,
                      child: GestureDetector(
                        onTap: controller.saveNote,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.folderYellow,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Obx(() => controller.isSaving.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  CupertinoIcons.checkmark,
                                  color: Colors.white,
                                  size: 18,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBarIcon(BuildContext context, IconData icon, {required VoidCallback onTap}) {
    return LiquidGlassContainer(
      width: 40,
      height: 40,
      borderRadius: 20,
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Icon(
            icon,
            color: AppTheme.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _toolbarIcon(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return LiquidGlassContainer(
      width: 40,
      height: 40,
      borderRadius: 20,
      opacity: 0.1,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final noteDate = controller.currentNote.value?.updatedAt ?? DateTime.now();
    final horizontalInset = _editorInset(context);

    return _pageContent(
      ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(horizontalInset, 8, horizontalInset, 120),
        children: [
          Center(
            child: Text(
              DateFormat("MMMM d, yyyy 'at' h:mm a").format(noteDate),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('note-title-field'),
            controller: controller.titleController,
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
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in controller.blocks.asMap().entries)
            _buildBlock(context, entry.value, entry.key),
        ],
      ),
    );
  }

  Widget _buildBlock(BuildContext context, NoteBlock block, int blockIndex) {
    final theme = Theme.of(context);
    if (block is TextBlock) {
      final textController = controller.getTextController(block.id, block.text);

      TextStyle? textStyle;
      switch (block.style) {
        case 'title':
          textStyle = theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold);
          break;
        case 'heading':
          textStyle = theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
          break;
        default:
          textStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.45);
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: TextField(
          key: ValueKey('note-text-${block.id}'),
          controller: textController,
          onTap: () => controller.activeBlockIndex = blockIndex,
          cursorColor: AppTheme.folderYellow,
          cursorWidth: 1.5,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          scrollPadding: const EdgeInsets.only(bottom: 92),
          onChanged: (value) => controller.updateTextBlock(blockIndex, value),
          style: textStyle,
          decoration: InputDecoration(
            hintText: 'Start writing...',
            hintStyle: textStyle?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isCollapsed: true,
          ),
        ),
      );
    }

    if (block is ChecklistBlock) {
      return _buildChecklistBlock(context, block, blockIndex);
    }

    if (block is AttachmentBlock) {
      return _buildAttachmentBlock(context, block);
    }

    if (block is TableBlock) {
      return _buildTableBlock(context, block);
    }

    if (block is DrawingBlock) {
      return _buildDrawingBlock(context, block);
    }

    return const SizedBox.shrink();
  }

  Widget _buildDrawingBlock(BuildContext context, DrawingBlock block) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InteractiveDrawingCanvas(
        onSave: (path) {
          // Logic handled in controller
        },
      ),
    );
  }

  Widget _buildTableBlock(BuildContext context, TableBlock block) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.all(color: theme.dividerColor, width: 0.5),
        children: [
          for (final row in block.rows)
            TableRow(
              children: [
                for (final cell in row)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(cell, style: theme.textTheme.bodyMedium),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistBlock(
    BuildContext context,
    ChecklistBlock block,
    int blockIndex,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          for (final entry in block.items.asMap().entries)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  button: true,
                  checked: entry.value.checked,
                  label: entry.value.checked
                      ? 'Mark checklist item incomplete'
                      : 'Mark checklist item complete',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        controller.toggleChecklistItem(blockIndex, entry.key),
                    child: SizedBox(
                      width: 31,
                      height: 31,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          entry.value.checked
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.circle,
                          color: entry.value.checked
                              ? AppTheme.folderYellow
                              : theme.colorScheme.onSurfaceVariant,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: ValueKey('checklist-${block.id}-${entry.value.id}'),
                    controller: controller.getTextController(
                      '${block.id}_${entry.key}',
                      entry.value.text,
                    ),
                    cursorColor: AppTheme.folderYellow,
                    cursorWidth: 1.5,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    scrollPadding: const EdgeInsets.only(bottom: 92),
                    onChanged: (value) => controller.onUpdateChecklistItem(
                      blockIndex,
                      entry.key,
                      value,
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.45,
                      decoration: entry.value.checked
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentBlock(BuildContext context, AttachmentBlock block) {
    final attachment = _attachmentImage(context, block);
    final semanticsLabel = block.displayName.trim().isEmpty
        ? 'Note attachment'
        : 'Attachment: ${block.displayName}';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          image: true,
          label: semanticsLabel,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 150,
              height: 200,
              child: attachment,
            ),
          ),
        ),
      ),
    );
  }

  Widget _attachmentImage(BuildContext context, AttachmentBlock block) {
    final errorPlaceholder = _attachmentPlaceholder(context);

    if (block.localPath != null && block.localPath!.isNotEmpty) {
      final file = File(block.localPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => errorPlaceholder,
        );
      }
    }

    if (block.url != null && block.url!.isNotEmpty) {
      return Image.network(
        block.url!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => errorPlaceholder,
      );
    }

    return errorPlaceholder;
  }

  Widget _attachmentPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 27,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEditingToolbar(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = bottomInset > 0;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Container(
        padding: EdgeInsets.only(bottom: isKeyboardVisible ? 0 : 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: _pageContent(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: isKeyboardVisible ? MainAxisAlignment.spaceAround : MainAxisAlignment.start,
                      children: [
                        _toolbarIcon(
                          context,
                          icon: CupertinoIcons.textformat, // "Aa"
                          onTap: () => _showFormattingPopup(context),
                        ),
                        if (!isKeyboardVisible) const SizedBox(width: 24),
                        _toolbarIcon(
                          context,
                          icon: CupertinoIcons.list_bullet, // Checklist
                          onTap: controller.addChecklistBlock,
                        ),
                        if (!isKeyboardVisible) const SizedBox(width: 24),
                        _toolbarIcon(
                          context,
                          icon: CupertinoIcons.table, // Table
                          onTap: controller.addTableBlock,
                        ),
                        if (!isKeyboardVisible) const SizedBox(width: 24),
                        _toolbarIcon(
                          context,
                          icon: CupertinoIcons.paperclip, // Attachment
                          onTap: () => _showAttachmentPopup(context),
                        ),
                        if (!isKeyboardVisible) const SizedBox(width: 24),
                        _toolbarIcon(
                          context,
                          icon: CupertinoIcons.pencil_circle, // Markup (pencil circle)
                          onTap: controller.addDrawingBlock,
                        ),
                      ],
                    ),
                  ),

                  if (!isKeyboardVisible)
                    LiquidGlassContainer(
                      width: 44,
                      height: 44,
                      borderRadius: 22,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.square_pencil,
                            color: AppTheme.folderYellow,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageContent(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }

  void _showAttachmentPopup(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Attachment"),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.addAttachment(ImageSource.camera);
            },
            child: const Text("Take Photo"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.addAttachment(ImageSource.gallery);
            },
            child: const Text("Photo Library"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.addAttachment(ImageSource.camera, isVideo: true);
            },
            child: const Text("Take Video"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back(),
          isDefaultAction: true,
          child: const Text("Cancel"),
        ),
      ),
    );
  }

  void _showFormattingPopup(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Text Format"),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              int index = controller.blocks.length - 1;
              controller.updateTextBlockStyle(index, 'title');
            },
            child: const Text("Title"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              int index = controller.blocks.length - 1;
              controller.updateTextBlockStyle(index, 'heading');
            },
            child: const Text("Heading"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              int index = controller.blocks.length - 1;
              controller.updateTextBlockStyle(index, 'body');
            },
            child: const Text("Body"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back(),
          isDefaultAction: true,
          child: const Text("Cancel"),
        ),
      ),
    );
  }

  double _editorInset(BuildContext context) {
    return (MediaQuery.sizeOf(context).width * 0.065).clamp(21.0, 32.0);
  }
}

class InteractiveDrawingCanvas extends StatefulWidget {
  final Function(String path)? onSave;
  const InteractiveDrawingCanvas({super.key, this.onSave});

  @override
  State<InteractiveDrawingCanvas> createState() => _InteractiveDrawingCanvasState();
}

class _InteractiveDrawingCanvasState extends State<InteractiveDrawingCanvas> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 400,
      width: double.infinity,
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                _points.add(renderBox.globalToLocal(details.localPosition));
              });
            },
            onPanEnd: (details) {
              _points.add(null);
            },
            child: CustomPaint(
              painter: DrawingPainter(points: _points, color: theme.colorScheme.onSurface),
              size: Size.infinite,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => setState(() => _points.clear()),
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  DrawingPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
