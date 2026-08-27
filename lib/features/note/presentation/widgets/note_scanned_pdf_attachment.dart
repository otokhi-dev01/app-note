import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/core/utils/share_helper.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';

/// Renders the actual first PDF page inside the note, so the inline card is a
/// faithful paper preview of the file that will be shared or printed.
class NotePdfAttachment extends StatefulWidget {
  final AttachmentBlock block;
  final NoteDetailController controller;
  final bool isReadOnly;
  final VoidCallback onDelete;

  const NotePdfAttachment({
    super.key,
    required this.block,
    required this.controller,
    required this.isReadOnly,
    required this.onDelete,
  });

  @override
  State<NotePdfAttachment> createState() => _NotePdfAttachmentState();
}

class _NotePdfAttachmentState extends State<NotePdfAttachment> {
  final _menuController = lg.GlassMenuController();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.block.displayName.trim();

    return Semantics(
      button: true,
      label: 'note_editor_attached_file_semantic_label'.trParams({
        'name': name,
      }),
      child: lg.GlassMenu(
        controller: _menuController,
        menuWidth: 250,
        autoAdjustToScreen: true,
        menuPadding: const EdgeInsets.all(12),
        morphFromZero: true,
        triggerBuilder: (context, _) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openPdf,
          onLongPress: _menuController.open,
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
        items: [
          lg.GlassMenuItem(
            title: 'note_editor_open_pdf'.tr,
            icon: const Icon(
              CupertinoIcons.doc_text_search,
              color: IosSemanticColors.blue,
            ),
            onTap: _openPdf,
          ),
          lg.GlassMenuItem(
            title: 'note_editor_share_print_pdf'.tr,
            icon: const Icon(
              CupertinoIcons.share,
              color: IosSemanticColors.blue,
            ),
            onTap: _shareOrPrint,
          ),
          if (!widget.isReadOnly) ...[
            const lg.GlassMenuDivider(),
            lg.GlassMenuItem(
              title: 'note_editor_delete'.tr,
              icon: const Icon(
                CupertinoIcons.trash,
                color: IosSemanticColors.red,
              ),
              isDestructive: true,
              onTap: widget.onDelete,
            ),
          ],
        ],
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
