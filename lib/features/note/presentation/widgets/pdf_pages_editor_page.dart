import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ios_image_editor/ios_image_editor.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/utils/image_pdf.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

typedef SavePdfPages = Future<bool> Function(List<String> pagePaths);
typedef RenderPdfPages = Future<List<String>> Function(String pdfPath);

/// Shows every PDF page as an editable thumbnail while preserving page order.
class PdfPagesEditorPage extends StatefulWidget {
  final String pdfPath;
  final SavePdfPages onSave;
  final RenderPdfPages? pageRenderer;

  const PdfPagesEditorPage({
    super.key,
    required this.pdfPath,
    required this.onSave,
    this.pageRenderer,
  });

  @override
  State<PdfPagesEditorPage> createState() => _PdfPagesEditorPageState();
}

class _PdfPagesEditorPageState extends State<PdfPagesEditorPage> {
  final List<String> _pages = <String>[];
  final Set<String> _temporaryPaths = <String>{};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPages());
  }

  @override
  void dispose() {
    unawaited(_cleanTemporaryFiles());
    super.dispose();
  }

  Future<void> _loadPages() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final renderedPages =
          await (widget.pageRenderer ?? renderPdfPagesForImageEditing)(
            widget.pdfPath,
          );
      if (!mounted) {
        await _deletePaths(renderedPages);
        return;
      }
      _temporaryPaths.addAll(renderedPages);
      setState(() {
        _pages
          ..clear()
          ..addAll(renderedPages);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  Future<void> _editPage(int index) async {
    if (_isSaving || index < 0 || index >= _pages.length) return;
    try {
      final editedPath = await IOSImageEditor.editImage(_pages[index]);
      if (!mounted || editedPath == null || editedPath.isEmpty) return;
      _temporaryPaths.add(editedPath);
      setState(() {
        _pages[index] = editedPath;
        _hasChanges = true;
      });
    } catch (error) {
      debugPrint('[PDF PAGE EDIT ERROR] $error');
      AppSnackbar.error(
        'note_editor_error_title'.tr,
        'note_editor_could_not_open_image_editor'.tr,
      );
    }
  }

  Future<void> _save() async {
    if (_isSaving || _pages.isEmpty) return;
    if (!_hasChanges) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSaving = true);
    final saved = await widget.onSave(List<String>.unmodifiable(_pages));
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) Navigator.of(context).pop(true);
  }

  Future<void> _cleanTemporaryFiles() => _deletePaths(_temporaryPaths);

  Future<void> _deletePaths(Iterable<String> paths) async {
    for (final path in paths.toSet()) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {
        // Editor inputs are temporary; cleanup is best effort.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const ValueKey('pdf-pages-editor-page'),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomGlassAppBar(
        key: const ValueKey('pdf-pages-editor-app-bar'),
        toolbarHeight: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: CustomGlassButton(
          key: const ValueKey('pdf-pages-editor-close'),
          semanticLabel: 'note_editor_cancel'.tr,
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          width: 44,
          height: 44,
          shape: GlassShape.circle,
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.xmark,
            color: theme.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          'note_editor_edit_pdf'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          CustomGlassButton(
            key: const ValueKey('pdf-pages-editor-done'),
            semanticLabel: 'note_editor_done'.tr,
            onPressed: _isLoading || _pages.isEmpty || _isSaving ? null : _save,
            height: 44,
            borderRadius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CupertinoActivityIndicator(radius: 9),
                  )
                : Text(
                    'note_editor_done'.tr,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 17,
                    ),
                  ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }
    if (_loadError != null || _pages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 36),
              const SizedBox(height: 12),
              Text(
                'note_editor_pdf_preview_failed'.tr,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadPages,
                child: Text('note_list_retry'.tr),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      key: const ValueKey('pdf-pages-editor-grid'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 18,
        crossAxisSpacing: 14,
        childAspectRatio: 0.67,
      ),
      itemCount: _pages.length,
      itemBuilder: (context, index) => _PdfEditablePageCard(
        key: ValueKey('pdf-edit-page-${index + 1}'),
        path: _pages[index],
        pageNumber: index + 1,
        onTap: () => _editPage(index),
      ),
    );
  }
}

class _PdfEditablePageCard extends StatelessWidget {
  final String path;
  final int pageNumber;
  final VoidCallback onTap;

  const _PdfEditablePageCard({
    super.key,
    required this.path,
    required this.pageNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${'note_editor_pdf_page'.tr} $pageNumber',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(path),
                          fit: BoxFit.contain,
                          cacheWidth: 600,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.pencil,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${'note_editor_pdf_page'.tr} $pageNumber',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
