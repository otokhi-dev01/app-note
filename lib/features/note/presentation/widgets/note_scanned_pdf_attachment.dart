import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    final path = _resolvedPath;
    if (path == null || !File(path).existsSync()) {
      AppSnackbar.info(
        'note_editor_not_available_title'.tr,
        'note_editor_pdf_not_available'.tr,
      );
      return;
    }

    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ScannedPdfPreviewPage(path: path),
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
    await widget.controller.editPdfSourceImage(widget.blockIndex);
    if (mounted) await _loadPreview();
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
        onTap: _editPdf,
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

  const _ScannedPdfPreviewPage({required this.path});

  @override
  State<_ScannedPdfPreviewPage> createState() => _ScannedPdfPreviewPageState();
}

class _ScannedPdfPreviewPageState extends State<_ScannedPdfPreviewPage> {
  late final PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.path),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _shareOrPrint() =>
      shareXFilesSafely(context, [XFile(widget.path)]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF555555),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: PdfViewPinch(
                controller: _pdfController,
                padding: 18,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              top: 8,
              child: Row(
                children: [
                  _PdfOverlayButton(
                    icon: CupertinoIcons.xmark,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _PdfOverlayButton(
                    icon: CupertinoIcons.share,
                    onTap: _shareOrPrint,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfOverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PdfOverlayButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
