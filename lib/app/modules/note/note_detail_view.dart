import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/models/note_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import 'note_detail_controller.dart';

class NoteDetailView extends GetView<NoteDetailController> {
  const NoteDetailView({super.key});

  static const double _maxContentWidth = 600;
  static const double _topBarControlSize = 40;
  static const double _topBarSpacing = 15;
  static const double _toolbarIconSize = 40;
  static const double _attachmentWidth = 150;
  static const double _attachmentHeight = 200;
  static const double _editorBottomPadding = 120;
  static final Uri _attachmentBaseUri = Uri.parse('https://note.piisiit.com/');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiStyle(theme),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Obx(
              () => controller.isLoading.value
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    )
                  : Stack(
                      children: [
                        _buildEditor(context),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildEditingToolbar(context),
                        ),
                      ],
                    ),
            ),
            Column(
              children: [
                _buildTopBar(context),
                Obx(
                  () => controller.isReadOnly.value
                      ? _buildReadOnlyBanner(context)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SystemUiOverlayStyle _systemUiStyle(ThemeData theme) {
    final style = theme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return style.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(top: topPadding),
      child: _pageContent(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: _topBarControlSize,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassIconButton(
                  icon: CupertinoIcons.chevron_left,
                  onTap: Get.back,
                  size: 44,
                  iconSize: 28,
                ),
                Row(
                  children: [
                    _buildGlassIconButton(
                      icon: CupertinoIcons.arrow_uturn_left,
                      onTap: () {},
                    ),
                    const SizedBox(width: _topBarSpacing),
                    _buildGlassIconButton(
                      icon: CupertinoIcons.share,
                      onTap: () {},
                    ),
                    const SizedBox(width: _topBarSpacing),
                    _buildGlassIconButton(
                      icon: Icons.more_horiz,
                      onTap: () {},
                    ),
                    const SizedBox(width: _topBarSpacing),
                    Obx(
                          () => controller.isReadOnly.value
                          ? const SizedBox.shrink()
                          : _buildSaveButton(),
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

  Widget _buildSaveButton() {
    return LiquidGlassContainer(
      width: _topBarControlSize,
      height: _topBarControlSize,
      borderRadius: _topBarControlSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.saveNote,
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.folderYellow,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Obx(
                () => controller.isSaving.value
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
              color: AppTheme.bodyColor,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = _topBarControlSize,
    double iconSize = 22,
    double opacity = 0.15,
    Color color = AppTheme.textSecondary,
  }) {
    return LiquidGlassContainer(
      width: size,
      height: size,
      borderRadius: size / 2,
      opacity: opacity,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onTap,
        icon: Icon(icon, color: color, size: iconSize),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final noteDate = controller.currentNote.value?.updatedAt ?? DateTime.now();
    final horizontalInset = _editorInset(context);
    final topPadding = MediaQuery.paddingOf(context).top + _topBarControlSize + 16;

    return _pageContent(
      ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          topPadding,
          horizontalInset,
          _editorBottomPadding,
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
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in controller.blocks.asMap().entries)
            _buildBlock(context, entry.value, entry.key),
        ],
      ),
    );
  }

  Widget _buildBlock(
      BuildContext context,
      NoteBlock block,
      int blockIndex,
      ) {
    if (block is TextBlock) {
      return _buildTextBlock(context, block, blockIndex);
    }

    if (block is ChecklistBlock) {
      return _buildChecklistBlock(context, block, blockIndex);
    }

    if (block is AttachmentBlock) {
      return _buildAttachmentBlock(context, block, blockIndex);
    }

    if (block is TableBlock) {
      return _buildTableBlock(context, block);
    }

    if (block is DrawingBlock) {
      return _buildDrawingBlock(block);
    }

    return const SizedBox.shrink();
  }

  Widget _buildTextBlock(
      BuildContext context,
      TextBlock block,
      int blockIndex,
      ) {
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
                    onTap: () => controller.toggleChecklistItem(
                      blockIndex,
                      entry.key,
                    ),
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
                    key: ValueKey(
                      'checklist-${block.id}-${entry.value.id}',
                    ),
                    controller: controller.getTextController(
                      '${block.id}_${entry.value.id}',
                      entry.value.text,
                    ),
                    enabled: !controller.isReadOnly.value,
                    onChanged: (value) => controller.onUpdateChecklistItem(
                      blockIndex,
                      entry.key,
                      value,
                    ),
                    cursorColor: AppTheme.folderYellow,
                    cursorWidth: 1.5,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    scrollPadding: const EdgeInsets.only(bottom: 92),
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

  Widget _buildAttachmentBlock(
      BuildContext context,
      AttachmentBlock block,
      int blockIndex,
      ) {
    final semanticsLabel = block.displayName.trim().isEmpty
        ? 'Note attachment'
        : 'Attachment: ${block.displayName}';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          image: true,
          label: '$semanticsLabel. Tap to preview and edit.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openImageEditor(
              block,
              blockIndex,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: _attachmentWidth,
                    height: _attachmentHeight,
                    child: _attachmentImage(context, block),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.pencil,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openImageEditor(
      AttachmentBlock block,
      int blockIndex,
      ) async {
    final imageProvider = _resolveAttachmentImageProvider(block);

    if (imageProvider == null) {
      Get.snackbar(
        'Image unavailable',
        'The image file could not be opened.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final canEdit = !controller.isReadOnly.value;
    final String? editedPath = await Get.to<String>(
          () => ImageDrawingEditor(
        imageProvider: imageProvider,
        title: block.displayName.trim().isEmpty
            ? 'Image Preview'
            : block.displayName,
        canEdit: canEdit,
      ),
    );

    if (!canEdit || editedPath == null || editedPath.isEmpty) return;

    controller.updateAttachmentImage(
      blockIndex,
      editedPath,
    );
  }
  ImageProvider? _resolveAttachmentImageProvider(
      AttachmentBlock block,
      ) {
    final localPath = _normalizeLocalPath(block.localPath);

    if (localPath != null) {
      final file = File(localPath);
      if (file.existsSync()) return FileImage(file);
    }

    final networkUrl = _normalizeAttachmentUrl(block.url);
    if (networkUrl != null) return NetworkImage(networkUrl);

    return null;
  }

  Widget _attachmentImage(
      BuildContext context,
      AttachmentBlock block,
      ) {
    final placeholder = _attachmentPlaceholder(context);
    final localPath = _normalizeLocalPath(block.localPath);
    final networkUrl = _normalizeAttachmentUrl(block.url);

    if (localPath != null) {
      final file = File(localPath);

      if (file.existsSync()) {
        return Image.file(
          file,
          key: ValueKey('local-${block.id}-$localPath'),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, error, stackTrace) {
            _debugAttachmentError(
              message: 'Local attachment image failed',
              source: localPath,
              error: error,
              stackTrace: stackTrace,
            );

            return networkUrl == null
                ? placeholder
                : _networkAttachmentImage(
              blockId: block.id,
              url: networkUrl,
              placeholder: placeholder,
            );
          },
        );
      }

      _debugAttachmentError(
        message: 'Local attachment file not found',
        source: localPath,
      );
    }

    if (networkUrl != null) {
      return _networkAttachmentImage(
        blockId: block.id,
        url: networkUrl,
        placeholder: placeholder,
      );
    }

    _debugAttachmentError(
      message: 'Attachment has no usable image source',
      source:
      'id=${block.id}, localPath=${block.localPath}, url=${block.url}',
    );

    return placeholder;
  }

  Widget _networkAttachmentImage({
    required String blockId,
    required String url,
    required Widget placeholder,
  }) {
    return Image.network(
      url,
      key: ValueKey('network-$blockId-$url'),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;

        final totalBytes = progress.expectedTotalBytes;
        final value = totalBytes == null
            ? null
            : progress.cumulativeBytesLoaded / totalBytes;

        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: value,
              color: AppTheme.folderYellow,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (_, error, stackTrace) {
        _debugAttachmentError(
          message: 'Network attachment image failed',
          source: url,
          error: error,
          stackTrace: stackTrace,
        );

        return placeholder;
      },
    );
  }

  String? _normalizeLocalPath(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final path = value.trim();

    if (!path.startsWith('file://')) return path;

    final uri = Uri.tryParse(path);
    return uri?.toFilePath();
  }

  String? _normalizeAttachmentUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    String path = value.trim().replaceAll('\\', '/');

    if (path.startsWith('~/')) {
      path = path.substring(2);
    }

    final uri = Uri.tryParse(path);

    if (uri != null && uri.hasScheme) {
      return uri.toString();
    }

    try {
      return _attachmentBaseUri.resolve(path).toString();
    } catch (error, stackTrace) {
      _debugAttachmentError(
        message: 'Invalid attachment URL',
        source: path,
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  void _debugAttachmentError({
    required String message,
    required String source,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    debugPrint('$message: $source');

    if (error != null) {
      debugPrint('Attachment error: $error');
    }

    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
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

  Widget _buildTableBlock(
      BuildContext context,
      TableBlock block,
      ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.all(
          color: theme.dividerColor,
          width: 0.5,
        ),
        children: [
          for (final row in block.rows)
            TableRow(
              children: [
                for (final cell in row)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      cell,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDrawingBlock(DrawingBlock block) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InteractiveDrawingCanvas(
        key: ValueKey('drawing-${block.id}'),
        onSave: (_) {},
      ),
    );
  }

  Widget _buildEditingToolbar(BuildContext context) {
    if (controller.isReadOnly.value) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: LiquidGlassContainer(
        padding: EdgeInsets.only(
          bottom: isKeyboardVisible ? 10 : 12,
        ),
        child: SafeArea(
          top: false,
          child: _pageContent(
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: isKeyboardVisible
                          ? MainAxisAlignment.spaceAround
                          : MainAxisAlignment.start,
                      children: [
                        _buildToolbarButton(
                          context,
                          icon: CupertinoIcons.textformat,
                          onTap: () => _showFormattingPopup(context),
                        ),
                        if (!isKeyboardVisible)
                          const SizedBox(width: 25),
                        _buildToolbarButton(
                          context,
                          icon: CupertinoIcons.list_bullet,
                          onTap: controller.addChecklistBlock,
                        ),
                        if (!isKeyboardVisible)
                          const SizedBox(width: 25),
                        _buildToolbarButton(
                          context,
                          icon: CupertinoIcons.table,
                          onTap: controller.addTableBlock,
                        ),
                        if (!isKeyboardVisible)
                          const SizedBox(width: 25),
                        _buildToolbarButton(
                          context,
                          icon: CupertinoIcons.paperclip,
                          onTap: () => _showAttachmentPopup(context),
                        ),
                        if (!isKeyboardVisible)
                          const SizedBox(width: 25),
                        _buildToolbarButton(
                          context,
                          icon: CupertinoIcons.pen,
                          onTap: controller.addDrawingBlock,
                        ),
                      ],
                    ),
                  ),
                  if (!isKeyboardVisible)
                    _buildGlassIconButton(
                      icon: CupertinoIcons.square_pencil,
                      onTap: () {},
                      size: 44,
                      iconSize: 24,
                      color: AppTheme.folderYellow,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
      BuildContext context, {
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return _buildGlassIconButton(
      icon: icon,
      onTap: onTap,
      size: _toolbarIconSize,
      opacity: 0.1,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _pageContent(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _maxContentWidth,
        ),
        child: SizedBox(
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }

  void _showAttachmentPopup(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Attachment'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => _pickAttachment(
              ImageSource.camera,
            ),
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _pickAttachment(
              ImageSource.gallery,
            ),
            child: const Text('Photo Library'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _pickAttachment(
              ImageSource.camera,
              isVideo: true,
            ),
            child: const Text('Take Video'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: Get.back,
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _pickAttachment(
      ImageSource source, {
        bool isVideo = false,
      }) {
    Get.back();
    controller.addAttachment(source, isVideo: isVideo);
  }

  void _showFormattingPopup(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Text Format'),
        actions: [
          _formatAction('Title', 'title'),
          _formatAction('Heading', 'heading'),
          _formatAction('Body', 'body'),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: Get.back,
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  CupertinoActionSheetAction _formatAction(
      String label,
      String style,
      ) {
    return CupertinoActionSheetAction(
      onPressed: () {
        Get.back();

        final index = _activeTextBlockIndex();
        if (index >= 0) {
          controller.updateTextBlockStyle(index, style);
        }
      },
      child: Text(label),
    );
  }

  int _activeTextBlockIndex() {
    final activeIndex = controller.activeBlockIndex;

    if (activeIndex >= 0 &&
        activeIndex < controller.blocks.length &&
        controller.blocks[activeIndex] is TextBlock) {
      return activeIndex;
    }

    for (int index = controller.blocks.length - 1; index >= 0; index--) {
      if (controller.blocks[index] is TextBlock) {
        return index;
      }
    }

    return -1;
  }

  double _editorInset(BuildContext context) {
    return (MediaQuery.sizeOf(context).width * 0.065).clamp(
      21.0,
      32.0,
    );
  }

  Widget _buildReadOnlyBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This note is in Recently Deleted. Restore it to make changes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Tip',
                'Use Recently Deleted to restore this note.',
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'OK',
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
}

class InteractiveDrawingCanvas extends StatefulWidget {
  const InteractiveDrawingCanvas({
    super.key,
    this.onSave,
  });

  final ValueChanged<String>? onSave;

  @override
  State<InteractiveDrawingCanvas> createState() =>
      _InteractiveDrawingCanvasState();
}

class _InteractiveDrawingCanvasState
    extends State<InteractiveDrawingCanvas> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                setState(() => _points.add(details.localPosition));
              },
              onPanUpdate: (details) {
                setState(() => _points.add(details.localPosition));
              },
              onPanEnd: (_) {
                setState(() => _points.add(null));
              },
              child: CustomPaint(
                painter: DrawingPainter(
                  points: _points,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => setState(_points.clear),
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  const DrawingPainter({
    required this.points,
    required this.color,
  });

  final List<Offset?> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..isAntiAlias = true;

    for (int index = 0; index < points.length - 1; index++) {
      final currentPoint = points[index];
      final nextPoint = points[index + 1];

      if (currentPoint != null && nextPoint != null) {
        canvas.drawLine(currentPoint, nextPoint, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

class ImageDrawingEditor extends StatefulWidget {
  const ImageDrawingEditor({
    super.key,
    required this.imageProvider,
    this.title = 'Edit Image',
    this.canEdit = true,
  });

  final ImageProvider imageProvider;
  final String title;
  final bool canEdit;

  @override
  State<ImageDrawingEditor> createState() => _ImageDrawingEditorState();
}

class _ImageDrawingEditorState extends State<ImageDrawingEditor> {
  final GlobalKey _captureKey = GlobalKey();
  final List<ImageDrawingStroke> _strokes = [];

  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  Size? _imageSize;
  Object? _imageError;

  Color _selectedColor = Colors.red;
  double _brushWidth = 5;
  bool _isSaving = false;
  bool _didResolveImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didResolveImage) {
      _didResolveImage = true;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    final listener = _imageListener;
    if (listener != null) {
      _imageStream?.removeListener(listener);
    }
    super.dispose();
  }

  void _resolveImage() {
    final stream = widget.imageProvider.resolve(
      createLocalImageConfiguration(context),
    );

    final listener = ImageStreamListener(
          (info, _) {
        if (!mounted) return;

        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          _imageError = null;
        });
      },
      onError: (error, stackTrace) {
        if (!mounted) return;

        setState(() {
          _imageError = error;
        });

        if (kDebugMode) {
          debugPrint('Image editor failed to load image: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      },
    );

    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.canEdit) ...[
            IconButton(
              tooltip: 'Undo',
              onPressed: _strokes.isEmpty ? null : _undo,
              icon: const Icon(CupertinoIcons.arrow_uturn_left),
            ),
            IconButton(
              tooltip: 'Clear',
              onPressed: _strokes.isEmpty ? null : _clear,
              icon: const Icon(CupertinoIcons.trash),
            ),
            TextButton(
              onPressed: _imageSize == null || _isSaving
                  ? null
                  : _saveEditedImage,
              child: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.folderYellow,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.folderYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _buildEditorBody(),
            ),
            if (widget.canEdit) _buildDrawingToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorBody() {
    if (_imageError != null) {
      return const Center(
        child: Text(
          'Could not load this image.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final imageSize = _imageSize;

    if (imageSize == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.folderYellow,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageAspectRatio = imageSize.width / imageSize.height;
        final availableAspectRatio =
            constraints.maxWidth / constraints.maxHeight;

        final width = imageAspectRatio > availableAspectRatio
            ? constraints.maxWidth
            : constraints.maxHeight * imageAspectRatio;
        final height = width / imageAspectRatio;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: RepaintBoundary(
              key: _captureKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(
                    image: widget.imageProvider,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                  if (widget.canEdit)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: _startStroke,
                      onPanUpdate: _continueStroke,
                      child: CustomPaint(
                        painter: ImageDrawingPainter(
                          strokes: _strokes
                              .map((stroke) => stroke.copy())
                              .toList(growable: false),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawingToolbar() {
    final colors = <Color>[
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.blue,
      AppTheme.folderYellow,
    ];

    return Container(
      color: const Color(0xFF151515),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.pencil,
                color: Colors.white70,
                size: 20,
              ),
              Expanded(
                child: Slider(
                  value: _brushWidth,
                  min: 2,
                  max: 18,
                  activeColor: AppTheme.folderYellow,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() => _brushWidth = value);
                  },
                ),
              ),
              Text(
                _brushWidth.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final color in colors) ...[
                _buildColorButton(color),
                const SizedBox(width: 14),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final selected = _selectedColor == color;

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: selected ? 34 : 30,
        height: selected ? 34 : 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? AppTheme.folderYellow
                : Colors.white54,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  void _startStroke(DragStartDetails details) {
    setState(() {
      _strokes.add(
        ImageDrawingStroke(
          color: _selectedColor,
          width: _brushWidth,
          points: [details.localPosition],
        ),
      );
    });
  }

  void _continueStroke(DragUpdateDetails details) {
    if (_strokes.isEmpty) return;

    setState(() {
      _strokes.last.points.add(details.localPosition);
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(_strokes.clear);
  }

  Future<void> _saveEditedImage() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      final renderObject =
      _captureKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('Image editor is not ready.');
      }

      final image = await renderObject.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw StateError('Could not create the edited image.');
      }

      final file = File(
        '${Directory.systemTemp.path}/'
            'note_edited_${DateTime.now().microsecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(
        byteData.buffer.asUint8List(),
        flush: true,
      );

      if (!mounted) return;
      Get.back(result: file.path);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Could not save edited image: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (mounted) {
        Get.snackbar(
          'Error',
          'Could not save the edited image.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class ImageDrawingStroke {
  ImageDrawingStroke({
    required this.color,
    required this.width,
    required this.points,
  });

  final Color color;
  final double width;
  final List<Offset> points;

  ImageDrawingStroke copy() {
    return ImageDrawingStroke(
      color: color,
      width: width,
      points: List<Offset>.from(points),
    );
  }
}

class ImageDrawingPainter extends CustomPainter {
  const ImageDrawingPainter({
    required this.strokes,
  });

  final List<ImageDrawingStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }

      final path = Path()
        ..moveTo(
          stroke.points.first.dx,
          stroke.points.first.dy,
        );

      for (int index = 1; index < stroke.points.length; index++) {
        path.lineTo(
          stroke.points[index].dx,
          stroke.points[index].dy,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(
      covariant ImageDrawingPainter oldDelegate,
      ) {
    return oldDelegate.strokes != strokes;
  }
}

