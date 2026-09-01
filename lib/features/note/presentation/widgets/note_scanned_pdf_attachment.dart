import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ios_image_editor/ios_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/core/utils/image_pdf.dart';
import 'package:Note/core/utils/share_helper.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_media_context_menu.dart';
import 'package:Note/features/note/presentation/widgets/image_overlay_composer_page.dart';
import 'package:Note/features/note/presentation/widgets/pdf_pages_editor_page.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// Renders the actual first PDF page inside the note, so the inline card is a
/// faithful paper preview of the file that will be shared or printed.
class NotePdfAttachment extends StatefulWidget {
  final AttachmentBlock block;
  final int blockIndex;
  final NoteDetailController controller;
  final bool isReadOnly;
  final VoidCallback onDelete;

  const NotePdfAttachment({
    super.key,
    required this.block,
    required this.blockIndex,
    required this.controller,
    required this.isReadOnly,
    required this.onDelete,
  });

  @override
  State<NotePdfAttachment> createState() => _NotePdfAttachmentState();
}

class _NotePdfAttachmentState extends State<NotePdfAttachment> {
  Uint8List? _firstPageBytes;
  String? _resolvedPath;
  bool _isLoading = true;
  bool _hasError = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreview());
  }

  @override
  void didUpdateWidget(covariant NotePdfAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.localPath != widget.block.localPath ||
        oldWidget.block.url != widget.block.url) {
      unawaited(_loadPreview());
    }
  }

  Future<String?> _resolvePath() async {
    final localPath = normalizeLocalPath(widget.block.localPath);
    if (localPath != null && File(localPath).existsSync()) return localPath;

    final networkUrl = normalizeAttachmentUrl(widget.block.url);
    if (networkUrl == null) return null;
    return widget.controller.cacheAttachmentForPreview(
      networkUrl,
      extension: '.pdf',
    );
  }

  Future<void> _loadPreview() async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _firstPageBytes = null;
        _resolvedPath = null;
      });
    }

    PdfDocument? document;
    PdfPage? page;
    try {
      final path = await _resolvePath();
      if (path == null) throw StateError('PDF source is unavailable');

      document = await PdfDocument.openFile(path);
      page = await document.getPage(1);
      const renderWidth = 1000.0;
      final rendered = await page.render(
        width: renderWidth,
        height: renderWidth * page.height / page.width,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
        forPrint: true,
      );
      if (rendered == null) throw StateError('Could not render PDF page');

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _resolvedPath = path;
        _firstPageBytes = rendered.bytes;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('[PDF PREVIEW ERROR] $error');
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } finally {
      if (page != null && !page.isClosed) await page.close();
      if (document != null && !document.isClosed) await document.close();
    }
  }

  Future<void> _openPdf() async {
    // Opening the document should not depend on the thumbnail render having
    // completed successfully. A valid PDF can still be viewed when its inline
    // first-page preview could not be generated.
    final path = _resolvedPath ?? await _resolvePath();
    if (path == null || !File(path).existsSync()) {
      AppSnackbar.info(
        'note_editor_not_available_title'.tr,
        'note_editor_pdf_not_available'.tr,
      );
      return;
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ScannedPdfPreviewPage(
          path: path,
          title: widget.block.displayName.trim(),
          onEdit: widget.isReadOnly
              ? null
              : () {
                  unawaited(_editPdf());
                },
        ),
      ),
    );
  }

  Future<void> _shareOrPrint() async {
    final path = _resolvedPath;
    if (path == null || !File(path).existsSync()) {
      AppSnackbar.info(
        'note_editor_not_available_title'.tr,
        'note_editor_pdf_not_available'.tr,
      );
      return;
    }
    await shareXFilesSafely(context, [XFile(path)]);
  }

  Future<void> _editPdf() async {
    if (widget.isReadOnly) {
      await _openPdf();
      return;
    }

    final pdfPath = _resolvedPath ?? await _resolvePath();
    if (pdfPath == null || !File(pdfPath).existsSync()) {
      AppSnackbar.info(
        'note_editor_not_available_title'.tr,
        'note_editor_pdf_not_available'.tr,
      );
      return;
    }
    if (!mounted) return;

    final saved = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => PdfPagesEditorPage(
          pdfPath: pdfPath,
          pageRenderer: (_) => preparePdfPagesForEditing(
            pdfPath: pdfPath,
            blockId: widget.block.id,
          ),
          onSave: (pages, paperSize) =>
              widget.controller.updatePdfFromPageImages(
                widget.blockIndex,
                pages,
                paperSize: paperSize,
              ),
        ),
      ),
    );
    if (mounted && saved == true) await _loadPreview();
  }

  Future<void> _addImageOverlay() async {
    if (widget.isReadOnly) return;
    final pdfPath = _resolvedPath;
    if (pdfPath == null || !File(pdfPath).existsSync()) {
      AppSnackbar.info(
        'note_editor_not_available_title'.tr,
        'note_editor_pdf_not_available'.tr,
      );
      return;
    }

    final sourcePath = await findPdfSourceImage(widget.block.id);
    final sourceBacked = sourcePath != null && File(sourcePath).existsSync();
    String? generatedBasePath;
    final basePath = sourceBacked
        ? sourcePath
        : await () async {
            final bytes = _firstPageBytes;
            if (bytes == null) return null;
            final directory = await getTemporaryDirectory();
            final path =
                '${directory.path}/pdf_overlay_base_${DateTime.now().microsecondsSinceEpoch}.png';
            await File(path).writeAsBytes(bytes, flush: true);
            generatedBasePath = path;
            return path;
          }();
    if (basePath == null || !File(basePath).existsSync()) {
      AppSnackbar.error('Error', 'Could not prepare that PDF page');
      return;
    }

    String? composedPath;
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedImage == null || !mounted) return;

      composedPath = await Navigator.of(context).push<String>(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (_) => ImageOverlayComposerPage(
            baseImagePath: basePath,
            overlayImagePath: pickedImage.path,
          ),
        ),
      );
      if (composedPath == null || composedPath.isEmpty) return;

      final editedPath = await IOSImageEditor.editImage(composedPath);
      if (editedPath == null || editedPath.isEmpty) return;

      await widget.controller.updatePdfFirstPageFromImage(
        widget.blockIndex,
        editedImagePath: editedPath,
        originalPdfPath: pdfPath,
        sourceBacked: sourceBacked,
      );
      if (mounted) await _loadPreview();
    } catch (error) {
      debugPrint('[PDF ADD IMAGE ERROR] $error');
      AppSnackbar.error('Error', 'Could not add that image to the PDF');
    } finally {
      for (final path in [generatedBasePath, composedPath]) {
        if (path == null) continue;
        try {
          await File(path).delete();
        } catch (_) {
          // Temporary overlay files are best-effort cleanup.
        }
      }
    }
  }

  void _showContextMenu() {
    final theme = Theme.of(context);
    NoteMediaContextMenu.show(
      context: context,
      preview: ColoredBox(color: Colors.white, child: _buildPaper(theme)),
      previewHeight: 440,
      actions: [
        NoteMediaMenuAction(
          title: 'note_editor_copy'.tr,
          icon: CupertinoIcons.doc_on_doc,
          onTap: () => unawaited(
            widget.controller.copyAttachmentBlock(widget.blockIndex),
          ),
        ),
        if (!widget.isReadOnly)
          NoteMediaMenuAction(
            title: 'note_editor_paste'.tr,
            icon: Icons.content_paste_rounded,
            onTap: () => unawaited(
              widget.controller.pasteClipboardContent(
                afterIndex: widget.blockIndex,
              ),
            ),
          ),
        if (!widget.isReadOnly)
          NoteMediaMenuAction(
            title: 'note_editor_cut'.tr,
            icon: Icons.content_cut_rounded,
            onTap: () => unawaited(
              widget.controller.cutAttachmentBlock(widget.blockIndex),
            ),
          ),
        if (!widget.isReadOnly)
          NoteMediaMenuAction(
            title: 'note_editor_delete'.tr,
            icon: CupertinoIcons.trash,
            isDestructive: true,
            onTap: widget.onDelete,
          ),
        NoteMediaMenuAction(
          title: 'note_editor_share'.tr,
          icon: CupertinoIcons.share,
          onTap: () => unawaited(_shareOrPrint()),
        ),
        NoteMediaMenuAction(
          title: 'note_editor_open_pdf'.tr,
          icon: CupertinoIcons.doc_text_search,
          onTap: () => unawaited(_openPdf()),
        ),
        if (!widget.isReadOnly)
          NoteMediaMenuAction(
            title: 'note_editor_add_image'.tr,
            icon: CupertinoIcons.photo_on_rectangle,
            onTap: () => unawaited(_addImageOverlay()),
          ),
        if (!widget.isReadOnly)
          NoteMediaMenuAction(
            title: 'note_editor_edit_pdf'.tr,
            icon: CupertinoIcons.pencil,
            onTap: () => unawaited(_editPdf()),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.block.displayName.trim();

    return Semantics(
      button: true,
      label: 'note_editor_attached_file_semantic_label'.trParams({
        'name': name,
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openPdf,
        onLongPress: _showContextMenu,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: AspectRatio(
              aspectRatio: 1 / 1.4142,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _buildPaper(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaper(ThemeData theme) {
    final bytes = _firstPageBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.doc_richtext,
              color: theme.colorScheme.onSurfaceVariant,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              _hasError
                  ? 'note_editor_pdf_preview_failed'.tr
                  : 'note_editor_pdf_not_available'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannedPdfPreviewPage extends StatefulWidget {
  final String path;
  final String title;
  final VoidCallback? onEdit;

  const _ScannedPdfPreviewPage({
    required this.path,
    required this.title,
    required this.onEdit,
  });

  @override
  State<_ScannedPdfPreviewPage> createState() => _ScannedPdfPreviewPageState();
}

class _ScannedPdfPreviewPageState extends State<_ScannedPdfPreviewPage> {
  late final PdfControllerPinch _pdfController;
  final Set<int> _previewPointers = <int>{};
  Timer? _editHoldTimer;
  int? _editHoldPointer;
  Offset? _editHoldOrigin;
  int _currentPage = 1;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.path),
    );
  }

  @override
  void dispose() {
    _cancelEditHold();
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _shareOrPrint() =>
      shareXFilesSafely(context, [XFile(widget.path)]);

  void _editPdf({bool fromHold = false}) {
    final onEdit = widget.onEdit;
    if (onEdit == null) return;

    if (fromHold) Feedback.forLongPress(context);
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => onEdit());
  }

  void _handleDocumentLoaded(PdfDocument document) {
    if (!mounted) return;
    setState(() => _pageCount = document.pagesCount);
  }

  void _handlePageChanged(int page) {
    if (!mounted || page == _currentPage) return;
    setState(() => _currentPage = page);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _previewPointers.add(event.pointer);
    if (widget.onEdit == null || _previewPointers.length != 1) {
      _cancelEditHold();
      return;
    }

    _editHoldPointer = event.pointer;
    _editHoldOrigin = event.position;
    _editHoldTimer = Timer(kLongPressTimeout, () {
      if (!mounted ||
          _previewPointers.length != 1 ||
          !_previewPointers.contains(_editHoldPointer)) {
        return;
      }
      _editPdf(fromHold: true);
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _editHoldPointer) return;
    final origin = _editHoldOrigin;
    if (origin == null || (event.position - origin).distance > kTouchSlop) {
      _cancelEditHold();
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    _previewPointers.remove(event.pointer);
    if (event.pointer == _editHoldPointer) _cancelEditHold();
  }

  void _cancelEditHold() {
    _editHoldTimer?.cancel();
    _editHoldTimer = null;
    _editHoldPointer = null;
    _editHoldOrigin = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.title.isEmpty
        ? 'note_editor_scanned_document_default_title'.tr
        : widget.title;
    final overlayStyle = theme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        key: const ValueKey('pdf-preview-page'),
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomGlassAppBar(
          key: const ValueKey('pdf-preview-app-bar'),
          toolbarHeight: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: CustomGlassButton(
            key: const ValueKey('pdf-preview-close'),
            semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            width: 44,
            height: 44,
            shape: GlassShape.circle,
            blur: 10,
            opacity: 0.15,
            thickness: 8,
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.xmark,
              color: theme.primaryColor,
              size: 22,
            ),
          ),
          title: Column(
            key: const ValueKey('pdf-preview-title'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (_pageCount > 0)
                Text(
                  '${'note_editor_pdf_page'.tr} $_currentPage '
                  '${'note_editor_pdf_of'.tr} $_pageCount',
                  key: const ValueKey('pdf-preview-page-count'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          actions: [
            if (widget.onEdit != null)
              CustomGlassButton(
                key: const ValueKey('pdf-preview-edit'),
                semanticLabel: 'note_editor_edit_pdf'.tr,
                onPressed: _editPdf,
                height: 44,
                borderRadius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                blur: 10,
                opacity: 0.15,
                thickness: 8,
                child: Text(
                  'folder_edit'.tr,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 17,
                  ),
                ),
              ),
            CustomGlassButton(
              key: const ValueKey('pdf-preview-share'),
              semanticLabel: 'note_editor_share_print_pdf'.tr,
              onPressed: _shareOrPrint,
              width: 44,
              height: 44,
              shape: GlassShape.circle,
              blur: 10,
              opacity: 0.15,
              thickness: 8,
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.share,
                color: theme.primaryColor,
                size: 22,
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Semantics(
            onLongPress: widget.onEdit == null
                ? null
                : () => _editPdf(fromHold: true),
            child: Listener(
              key: const ValueKey('pdf-preview-document'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerEnd,
              onPointerCancel: _handlePointerEnd,
              child: PdfViewPinch(
                controller: _pdfController,
                scrollDirection: Axis.horizontal,
                padding: 18,
                onDocumentLoaded: _handleDocumentLoaded,
                onPageChanged: _handlePageChanged,
                backgroundDecoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x52000000),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
