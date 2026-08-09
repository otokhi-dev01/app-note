import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/note_model.dart';
import '../controllers/note_detail_controller.dart';
import 'image_drawing_editor.dart';

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

  static const double _attachmentWidth = 150;
  static const double _attachmentHeight = 200;
  static final Uri _attachmentBaseUri = Uri.parse('https://note.piisiit.com/');

  @override
  Widget build(BuildContext context) {
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
            onTap: () => _openImageEditor(context),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: _attachmentWidth,
                    height: _attachmentHeight,
                    child: _AttachmentImage(block: block),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openImageEditor(BuildContext context) async {
    final imageProvider = _resolveAttachmentImageProvider();

    if (imageProvider == null) {
      Get.snackbar(
        'Image unavailable',
        'The image file could not be opened.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final canEdit = !controller.isReadOnly.value;
    final dynamic result = await Get.to(
      () => ImageDrawingEditor(
        localPath: block.localPath,
        url: block.url,
        imageProvider: imageProvider,
        title: block.displayName.trim().isEmpty
            ? 'Image Preview'
            : block.displayName,
        canEdit: canEdit,
      ),
    );

    if (result == 'delete') {
      controller.deleteBlock(blockIndex);
      return;
    }

    if (!canEdit || result == null || result is! String || result.isEmpty)
      return;

    controller.updateAttachmentImage(blockIndex, result);
  }

  ImageProvider? _resolveAttachmentImageProvider() {
    final localPath = _normalizeLocalPath(block.localPath);

    if (localPath != null) {
      final file = File(localPath);
      if (file.existsSync()) return FileImage(file);
    }

    final networkUrl = _normalizeAttachmentUrl(block.url);
    if (networkUrl != null) return NetworkImage(networkUrl);

    return null;
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
    } catch (error) {
      if (kDebugMode) debugPrint('Error normalizing URL $path: $error');
      return null;
    }
  }
}

class _AttachmentImage extends StatelessWidget {
  final AttachmentBlock block;

  const _AttachmentImage({required this.block});

  @override
  Widget build(BuildContext context) {
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
      return Uri.parse('https://note.piisiit.com/').resolve(path).toString();
    } catch (error) {
      if (kDebugMode) debugPrint('Error resolving URL $path: $error');
      return null;
    }
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
      errorBuilder: (_, __, ___) => _AttachmentPlaceholder(),
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
