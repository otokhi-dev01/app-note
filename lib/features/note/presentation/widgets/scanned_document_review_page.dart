import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/note/domain/entities/scanned_document_draft.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

typedef ScanPageSource = Future<List<String>> Function();
typedef SaveScannedDocument = Future<bool> Function(ScannedDocumentDraft draft);

/// A scanner-style staging area between native capture and note insertion.
///
/// Adjustments remain non-destructive until Save. This makes cancellation
/// cheap and lets the processor avoid re-encoding untouched pages.
class ScannedDocumentReviewPage extends StatefulWidget {
  final List<String> initialPagePaths;
  final String initialTitle;
  final SaveScannedDocument onSave;
  final ScanPageSource? onScanMore;
  final ScanPageSource? onChoosePhotos;

  const ScannedDocumentReviewPage({
    super.key,
    required this.initialPagePaths,
    required this.initialTitle,
    required this.onSave,
    this.onScanMore,
    this.onChoosePhotos,
  });

  @override
  State<ScannedDocumentReviewPage> createState() =>
      _ScannedDocumentReviewPageState();
}

class _ScannedDocumentReviewPageState extends State<ScannedDocumentReviewPage> {
  late final TextEditingController _titleController;
  late final PageController _pageController;
  final List<_ReviewPageEntry> _pages = <_ReviewPageEntry>[];
  var _nextPageId = 0;
  var _selectedIndex = 0;
  var _isAdding = false;
  var _isSaving = false;

  _ReviewPageEntry _entryFor(String path) => _ReviewPageEntry(
    id: 'scan-review-${_nextPageId++}',
    draft: ScannedPageDraft(path: path),
  );

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _pageController = PageController();
    _pages.addAll(widget.initialPagePaths.map(_entryFor));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _selectPage(int index, {bool animate = true}) {
    if (index < 0 || index >= _pages.length) return;
    setState(() => _selectedIndex = index);
    if (!_pageController.hasClients) return;
    if (animate) {
      unawaited(
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  void _rotateSelected() {
    if (_pages.isEmpty || _isSaving) return;
    final entry = _pages[_selectedIndex];
    setState(() {
      entry.draft = entry.draft.copyWith(
        quarterTurns: (entry.draft.quarterTurns + 1) % 4,
      );
    });
  }

  void _cycleFilter() {
    if (_pages.isEmpty || _isSaving) return;
    final entry = _pages[_selectedIndex];
    final filters = ScanPageFilter.values;
    final next = filters[(entry.draft.filter.index + 1) % filters.length];
    setState(() => entry.draft = entry.draft.copyWith(filter: next));
  }

  Future<void> _deleteSelected() async {
    if (_pages.isEmpty || _isSaving) return;
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('note_editor_scan_remove_page'.tr),
        content: Text('note_editor_scan_remove_page_message'.tr),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('note_editor_cancel'.tr),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('note_editor_delete'.tr),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() {
      _pages.removeAt(_selectedIndex);
      if (_pages.isEmpty) {
        _selectedIndex = 0;
      } else if (_selectedIndex >= _pages.length) {
        _selectedIndex = _pages.length - 1;
      }
    });
    if (_pages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectPage(_selectedIndex, animate: false);
      });
    }
  }

  Future<void> _showAddPageMenu() async {
    if (_isAdding || _isSaving) return;
    final source = await showCupertinoModalPopup<ScanPageSource>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('note_editor_scan_add_page'.tr),
        actions: [
          if (widget.onScanMore != null)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(widget.onScanMore),
              child: Text('note_editor_scan_camera'.tr),
            ),
          if (widget.onChoosePhotos != null)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(widget.onChoosePhotos),
              child: Text('note_editor_scan_photos'.tr),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('note_editor_cancel'.tr),
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _isAdding = true);
    try {
      final added = await source();
      if (!mounted || added.isEmpty) return;
      final firstAddedIndex = _pages.length;
      setState(() => _pages.addAll(added.map(_entryFor)));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectPage(firstAddedIndex);
      });
    } catch (error) {
      debugPrint('[SCAN ADD PAGE ERROR] $error');
      AppSnackbar.error(
        'note_editor_error_title'.tr,
        'note_editor_scan_add_failed'.tr,
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving || _pages.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final saved = await widget.onSave(
        ScannedDocumentDraft(
          title: _titleController.text.trim(),
          pages: List<ScannedPageDraft>.unmodifiable(
            _pages.map((entry) => entry.draft),
          ),
        ),
      );
      if (saved && mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _reorderPages(int oldIndex, int newIndex) {
    if (_isSaving || oldIndex == newIndex) return;
    final selectedEntry = _pages.isEmpty ? null : _pages[_selectedIndex];
    setState(() {
      final moved = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, moved);
      if (selectedEntry != null) _selectedIndex = _pages.indexOf(selectedEntry);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pages.isNotEmpty) {
        _selectPage(_selectedIndex, animate: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        key: const ValueKey('scan-review-page'),
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomGlassAppBar(
          key: const ValueKey('scan-review-app-bar'),
          toolbarHeight: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: CustomGlassButton(
            key: const ValueKey('scan-review-cancel'),
            semanticLabel: 'note_editor_cancel'.tr,
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            width: 44,
            height: 44,
            shape: GlassShape.circle,
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.xmark,
              color: theme.primaryColor,
              size: 21,
            ),
          ),
          title: Text(
            'note_editor_scan_review'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            CustomGlassButton(
              key: const ValueKey('scan-review-save'),
              semanticLabel: 'note_editor_scan_save'.tr,
              onPressed: _pages.isEmpty || _isSaving ? null : _save,
              height: 44,
              borderRadius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CupertinoActivityIndicator(radius: 9),
                    )
                  : Text('note_editor_scan_save'.tr),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: CupertinoTextField(
                  key: const ValueKey('scan-review-title'),
                  controller: _titleController,
                  enabled: !_isSaving,
                  clearButtonMode: OverlayVisibilityMode.editing,
                  placeholder: 'note_editor_scan_document_name'.tr,
                  textCapitalization: TextCapitalization.words,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Expanded(child: _buildPreview(context)),
              _buildFilmstrip(context),
              _buildActionBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final theme = Theme.of(context);
    if (_pages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.doc_text_viewfinder,
                size: 52,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 14),
              Text(
                'note_editor_scan_no_pages'.tr,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isAdding ? null : _showAddPageMenu,
                icon: _isAdding
                    ? const CupertinoActivityIndicator()
                    : const Icon(CupertinoIcons.add),
                label: Text('note_editor_scan_add_page'.tr),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          key: const ValueKey('scan-review-preview'),
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 34),
            child: _ScannedPageImage(
              key: ValueKey('scan-review-image-${_pages[index].id}'),
              page: _pages[index].draft,
            ),
          ),
        ),
        Positioned(
          right: 28,
          bottom: 42,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                '${_selectedIndex + 1} / ${_pages.length}',
                key: const ValueKey('scan-review-page-count'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilmstrip(BuildContext context) {
    if (_pages.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return SizedBox(
      height: 96,
      child: ReorderableListView.builder(
        key: const ValueKey('scan-review-filmstrip'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        buildDefaultDragHandles: false,
        itemCount: _pages.length,
        onReorderItem: _reorderPages,
        proxyDecorator: (child, _, animation) => FadeTransition(
          opacity: animation.drive(Tween(begin: 0.8, end: 1.0)),
          child: Material(color: Colors.transparent, child: child),
        ),
        itemBuilder: (context, index) {
          final entry = _pages[index];
          final isSelected = index == _selectedIndex;
          return ReorderableDragStartListener(
            key: ValueKey(entry.id),
            index: index,
            enabled: !_isSaving,
            child: GestureDetector(
              onTap: () => _selectPage(index),
              child: AnimatedContainer(
                key: ValueKey('scan-review-thumbnail-$index'),
                duration: const Duration(milliseconds: 160),
                width: 62,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isSelected
                        ? IosSemanticColors.blue
                        : theme.dividerColor,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: _ScannedPageImage(page: entry.draft, thumbnail: true),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final disabled = _pages.isEmpty || _isSaving;
    final filter = _pages.isEmpty
        ? ScanPageFilter.color
        : _pages[_selectedIndex].draft.filter;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScanAction(
            key: const ValueKey('scan-review-add'),
            icon: _isAdding
                ? CupertinoIcons.hourglass
                : CupertinoIcons.add_circled,
            label: 'note_editor_scan_add'.tr,
            onPressed: _isAdding || _isSaving ? null : _showAddPageMenu,
          ),
          _ScanAction(
            key: const ValueKey('scan-review-rotate'),
            icon: CupertinoIcons.rotate_right,
            label: 'note_editor_scan_rotate'.tr,
            onPressed: disabled ? null : _rotateSelected,
          ),
          _ScanAction(
            key: const ValueKey('scan-review-filter'),
            icon: CupertinoIcons.circle_lefthalf_fill,
            label: _filterLabel(filter),
            onPressed: disabled ? null : _cycleFilter,
          ),
          _ScanAction(
            key: const ValueKey('scan-review-delete'),
            icon: CupertinoIcons.trash,
            label: 'note_editor_delete'.tr,
            color: IosSemanticColors.red,
            onPressed: disabled ? null : _deleteSelected,
          ),
        ],
      ),
    );
  }

  String _filterLabel(ScanPageFilter filter) => switch (filter) {
    ScanPageFilter.color => 'note_editor_scan_filter_color'.tr,
    ScanPageFilter.grayscale => 'note_editor_scan_filter_gray'.tr,
    ScanPageFilter.blackAndWhite => 'note_editor_scan_filter_bw'.tr,
  };
}

class _ReviewPageEntry {
  final String id;
  ScannedPageDraft draft;

  _ReviewPageEntry({required this.id, required this.draft});
}

class _ScannedPageImage extends StatelessWidget {
  final ScannedPageDraft page;
  final bool thumbnail;

  const _ScannedPageImage({
    super.key,
    required this.page,
    this.thumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.file(
      File(page.path),
      fit: BoxFit.contain,
      cacheWidth: thumbnail ? 180 : 1400,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(CupertinoIcons.exclamationmark_triangle, size: 32),
      ),
    );
    final filtered = switch (page.filter) {
      ScanPageFilter.color => image,
      ScanPageFilter.grayscale => ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: image,
      ),
      ScanPageFilter.blackAndWhite => ColorFiltered(
        colorFilter: const ColorFilter.matrix(_highContrastGrayscaleMatrix),
        child: image,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(thumbnail ? 5 : 12),
        boxShadow: thumbnail
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(thumbnail ? 5 : 12),
        child: RotatedBox(quarterTurns: page.quarterTurns, child: filtered),
      ),
    );
  }
}

class _ScanAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onPressed;

  const _ScanAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onPressed == null
        ? Theme.of(context).disabledColor
        : color ?? Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: InkResponse(
        onTap: onPressed,
        radius: 30,
        child: SizedBox(
          width: 72,
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: effectiveColor),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: effectiveColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _grayscaleMatrix = <double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

const _highContrastGrayscaleMatrix = <double>[
  0.34,
  1.14,
  0.12,
  0,
  -75,
  0.34,
  1.14,
  0.12,
  0,
  -75,
  0.34,
  1.14,
  0.12,
  0,
  -75,
  0,
  0,
  0,
  1,
  0,
];
