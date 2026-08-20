import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ios_image_editor/ios_image_editor.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:share_plus/share_plus.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/glass_surfaces.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/core/utils/image_pdf.dart';

const _imageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'heic',
  'heif',
  'webp',
  'bmp',
};

/// True if any source we have for this attachment carries a recognized image
/// extension.
///
/// Checking only the first non-null source (the old `a ?? b ?? c` version)
/// meant a block flipped between the file tile and the image tile across
/// saves: `url` sometimes comes back from the server as an extensionless
/// endpoint (e.g. `/api/attachment/123`), which — being non-null — used to
/// win over `displayName`'s perfectly good `.jpg` and short-circuit the
/// whole check. `displayName` is the most reliable source since it's set
/// once from the original file name and just carried forward, so every
/// source that's actually present gets a look, not just the first one.
bool _looksLikeImage(AttachmentBlock block) {
  for (final candidate in [block.displayName, block.localPath, block.url]) {
    final name = candidate?.trim() ?? '';
    if (name.isEmpty || !name.contains('.')) continue;
    if (_imageExtensions.contains(name.split('.').last.toLowerCase())) {
      return true;
    }
  }
  return false;
}

class NoteAttachmentBlock extends StatelessWidget {
  final AttachmentBlock block;
  final int blockIndex;
  final NoteDetailController controller;

  const NoteAttachmentBlock({
    super.key,
    required this.block,
    required this.blockIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!_looksLikeImage(block)) {
      final isPdf = looksLikePdf(block.displayName);
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: _FileTile(
          block: block,
          isReadOnly: controller.isReadOnly.value,
          isPdf: isPdf,
          onTap: () => _openOrShareFile(context),
          onLongPress: () => _showDeleteMenu(context, isImage: false),
          onDelete: () => controller.deleteBlock(blockIndex),
          // A PDF this app built from a picture is edited by going back to
          // that picture — the document is a rendered output, not the thing
          // being marked up. Offered for any PDF because whether the original
          // is still on this device is a question only the controller can
          // answer (it has to hit the filesystem), and it reports the miss.
          onEdit: isPdf
              ? () => controller.editPdfSourceImage(blockIndex)
              : null,
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final semanticsLabel = block.displayName.trim().isEmpty
        ? 'Note attachment'
        : 'Attachment: ${block.displayName}';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      // The tile pins itself to a concrete width rather than
      // `double.infinity`: GlassMenu lays its trigger out as a child of its
      // own Stack, and LayoutBuilder is what still reports the real bounded
      // width from the normal layout pass.
      child: LayoutBuilder(
        builder: (context, constraints) => _ImageTile(
          block: block,
          width: constraints.maxWidth,
          isReadOnly: controller.isReadOnly.value,
          semanticsLabel: semanticsLabel,
          isDark: isDark,
          onEdit: () => _openImageEditor(context),
          onConvertToPdf: () => controller.convertAttachmentToPdf(blockIndex),
          onShare: () => _shareImage(context),
          onDelete: () => controller.deleteBlock(blockIndex),
        ),
      ),
    );
  }

  Future<void> _openImageEditor(BuildContext context) async {
    if (controller.isReadOnly.value) return;

    String? pathToEdit = normalizeLocalPath(block.localPath);

    // 1. Prepare local path if it's a network URL
    if (pathToEdit == null || !File(pathToEdit).existsSync()) {
      final networkUrl = normalizeAttachmentUrl(block.url);
      if (networkUrl != null && networkUrl.isNotEmpty) {
        // The editor only works on local files, so pull the remote one down
        // first. The controller owns the transfer — widgets do not do I/O.
        await Get.showOverlay(
          asyncFunction: () async {
            pathToEdit = await controller.cacheAttachmentForEditing(networkUrl);
          },
          loadingWidget: const Center(
            child: CupertinoActivityIndicator(radius: 15, color: Colors.white),
          ),
        );
        if (pathToEdit == null) return;
      }
    }

    debugPrint('[IMAGE EDIT] Final Path: $pathToEdit');

    if (pathToEdit == null || !File(pathToEdit!).existsSync()) {
      AppSnackbar.error('Error', 'Image source not available');
      return;
    }

    try {
      // 2. Open native iOS Markup editor DIRECTLY
      final String? editedPath = await IOSImageEditor.editImage(pathToEdit!);
      if (editedPath != null && editedPath.isNotEmpty) {
        // Success: update the local block and automatically save the note
        controller.updateAttachmentImage(blockIndex, editedPath);
      }
    } catch (e) {
      debugPrint('Error opening native editor: $e');
      AppSnackbar.error('Error', 'Could not open image editor');
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    final path = normalizeLocalPath(block.localPath);
    if (path == null || !File(path).existsSync()) {
      AppSnackbar.info('Not available', 'This image isn\'t on the device.');
      return;
    }
    try {
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      debugPrint('[IMAGE SHARE ERROR] $e');
      AppSnackbar.error('Error', 'Could not share that image');
    }
  }

  void _showDeleteMenu(BuildContext context, {bool isImage = true}) {
    if (controller.isReadOnly.value) return;

    CustomGlassActionSheet.show(
      context: context,
      title: "Attachment Options",
      actions: [
        if (isImage)
          CustomGlassActionSheetAction(
            label: "Edit Image",
            icon: CupertinoIcons.pencil,
            onPressed: () => _openImageEditor(context),
          ),
        if (isImage)
          CustomGlassActionSheetAction(
            label: "Convert to PDF",
            icon: CupertinoIcons.doc_richtext,
            onPressed: () => controller.convertAttachmentToPdf(blockIndex),
          ),
        if (!isImage && looksLikePdf(block.displayName))
          CustomGlassActionSheetAction(
            label: "Edit Original Image",
            icon: CupertinoIcons.pencil,
            onPressed: () => controller.editPdfSourceImage(blockIndex),
          ),
        CustomGlassActionSheetAction(
          label: isImage ? "Delete Picture" : "Delete File",
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onPressed: () => controller.deleteBlock(blockIndex),
        ),
      ],
    );
  }

  /// Non-image attachments (PDFs, docs, …) have no in-app viewer, so tapping
  /// hands the file to the OS share sheet — "Open in…" lets the user view it
  /// in whatever app actually reads that format.
  Future<void> _openOrShareFile(BuildContext context) async {
    final path = normalizeLocalPath(block.localPath);
    if (path == null || !File(path).existsSync()) {
      AppSnackbar.info('Not available', 'This file isn\'t on the device.');
      return;
    }
    try {
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      debugPrint('[FILE SHARE ERROR] $e');
      AppSnackbar.error('Error', 'Could not open that file');
    }
  }
}

/// An image attachment, with its actions on a glass pull-down menu.
///
/// Stateful only to own the [lg.GlassMenuController]: the menu is opened by a
/// long press on the picture rather than by a tap on its own trigger — a tap
/// goes straight to the markup editor, as it did before — so something has to
/// drive it from outside, and that handle has to survive rebuilds.
class _ImageTile extends StatefulWidget {
  final AttachmentBlock block;
  final double width;
  final bool isReadOnly;
  final bool isDark;
  final String semanticsLabel;
  final VoidCallback onEdit;
  final VoidCallback onConvertToPdf;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _ImageTile({
    required this.block,
    required this.width,
    required this.isReadOnly,
    required this.isDark,
    required this.semanticsLabel,
    required this.onEdit,
    required this.onConvertToPdf,
    required this.onShare,
    required this.onDelete,
  });

  @override
  State<_ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<_ImageTile> {
  final _menuController = lg.GlassMenuController();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      image: true,
      label: '${widget.semanticsLabel}. Tap to edit, long press for options.',
      child: lg.GlassMenu(
        controller: _menuController,
        menuWidth: 250,
        // Left to auto-detect: an attachment can sit anywhere in a note, so
        // whether the menu has room to open downward depends on how far the
        // reader has scrolled — unlike the toolbar and app-bar menus, whose
        // triggers are pinned to one edge.
        autoAdjustToScreen: true,
        menuPadding: const EdgeInsets.all(12),
        // The trigger is the picture itself — far larger than the menu — so
        // the body blooms from a point rather than growing out of a glass
        // blob the size of the whole tile.
        morphFromZero: true,
        triggerBuilder: (context, _) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Tap still goes straight to the editor; the menu is what the long
          // press is for.
          onTap: widget.onEdit,
          onLongPress: _menuController.open,
          child: _buildImage(),
        ),
        items: _menuItems(),
      ),
    );
  }

  List<Widget> _menuItems() {
    return [
      lg.GlassMenuItem(
        title: 'Edit Image',
        icon: const Icon(CupertinoIcons.pencil),
        onTap: widget.onEdit,
      ),
      if (!widget.isReadOnly)
        lg.GlassMenuItem(
          title: 'Convert to PDF',
          icon: const Icon(CupertinoIcons.doc_richtext),
          onTap: widget.onConvertToPdf,
        ),
      lg.GlassMenuItem(
        title: 'Share',
        icon: const Icon(CupertinoIcons.share),
        onTap: widget.onShare,
      ),
      if (!widget.isReadOnly) ...[
        const lg.GlassMenuDivider(),
        lg.GlassMenuItem(
          title: 'Delete',
          icon: const Icon(CupertinoIcons.trash),
          isDestructive: true,
          onTap: widget.onDelete,
        ),
      ],
    ];
  }

  Widget _buildImage() {
    final block = widget.block;
    return Container(
      constraints: const BoxConstraints(maxHeight: 300, minHeight: 120),
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            SizedBox(
              width: double.infinity,
              height: 240,
              child: _AttachmentImage(block: block),
            ),
            if (block.displayName.trim().isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Text(
                    block.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentImage extends StatelessWidget {
  final AttachmentBlock block;

  const _AttachmentImage({required this.block});

  @override
  Widget build(BuildContext context) {
    final localPath = normalizeLocalPath(block.localPath);
    final networkUrl = normalizeAttachmentUrl(block.url);

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
            return networkUrl == null
                ? _AttachmentPlaceholder()
                : _NetworkAttachmentImage(blockId: block.id, url: networkUrl);
          },
        );
      }
    }

    if (networkUrl != null) {
      return _NetworkAttachmentImage(blockId: block.id, url: networkUrl);
    }

    return _AttachmentPlaceholder();
  }
}

class _NetworkAttachmentImage extends StatelessWidget {
  final String blockId;
  final String url;

  const _NetworkAttachmentImage({required this.blockId, required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      key: ValueKey('network-$blockId-$url'),
      headers: attachmentAuthHeaders(),
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
              color: Theme.of(context).primaryColor,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => _AttachmentPlaceholder(),
    );
  }
}

class _AttachmentPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}

/// Row shown for a non-image attachment — a picked file that has no in-app
/// preview, so it just gets an icon and its name (tap shares/opens it,
/// long-press offers delete).
class _FileTile extends StatelessWidget {
  final AttachmentBlock block;
  final bool isReadOnly;
  final bool isPdf;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  /// Reopens the picture a converted PDF was built from. `null` for anything
  /// with no image behind it, which hides the pencil entirely.
  final VoidCallback? onEdit;

  const _FileTile({
    required this.block,
    required this.isReadOnly,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    this.isPdf = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = block.displayName.trim().isEmpty
        ? 'Attachment'
        : block.displayName;
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : '';

    return Semantics(
      button: true,
      label: 'Attached file: $name',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPdf ? CupertinoIcons.doc_richtext : CupertinoIcons.doc,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (ext.isNotEmpty)
                      Text(
                        ext,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isReadOnly) ...[
                if (onEdit != null) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onEdit,
                    child: Icon(
                      CupertinoIcons.pencil,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(
                  CupertinoIcons.square_arrow_up,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
                const SizedBox(width: 12),
                // Own tap target so deleting doesn't depend on finding the
                // long-press menu — separate from the tile's own onTap
                // (open/share) above.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDelete,
                  child: Icon(
                    CupertinoIcons.trash,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
