import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ios_image_editor/ios_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart' as dio;
import '../../../data/models/note_model.dart';
import '../../../widgets/ios_action_menu.dart';
import '../controllers/note_detail_controller.dart';

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

  static final Uri _attachmentBaseUri = Uri.parse('https://note.piisiit.com/');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final semanticsLabel = block.displayName.trim().isEmpty
        ? 'Note attachment'
        : 'Attachment: ${block.displayName}';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Semantics(
        button: true,
        image: true,
        label: '$semanticsLabel. Tap to edit and save.',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openImageEditor(context, directEdit: true), // Logic: Tap to Edit instantly
          onLongPress: () => _showDeleteMenu(context), // Logic: Hold to show delete popup
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300, minHeight: 120),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
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
                  // "Tap to Edit" overlay hint
                  if (!controller.isReadOnly.value)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _openImageEditor(context, directEdit: true), // Logic: Direct pencil tool
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(
                            CupertinoIcons.pencil,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
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
          ),
        ),
      ),
    );
  }

  Future<void> _openImageEditor(BuildContext context, {bool directEdit = false}) async {
    if (controller.isReadOnly.value) return;

    String? pathToEdit = _normalizeLocalPath(block.localPath);
    
    // 1. Prepare local path if it's a network URL
    if (pathToEdit == null || !File(pathToEdit).existsSync()) {
      final networkUrl = _normalizeAttachmentUrl(block.url);
      if (networkUrl != null && networkUrl.isNotEmpty) {
        try {
          // Show quick loading overlay and WAIT for it to complete
          await Get.showOverlay(
            asyncFunction: () async {
              final directory = await getTemporaryDirectory();
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final localPath = '${directory.path}/edit_$timestamp.png';
              
              debugPrint('[IMAGE EDIT] Downloading: $networkUrl to $localPath');
              await dio.Dio().download(networkUrl, localPath);
              pathToEdit = localPath;
            },
            loadingWidget: const Center(
              child: CupertinoActivityIndicator(radius: 15, color: Colors.white),
            ),
          );
        } catch (e) {
          debugPrint('[IMAGE EDIT] Download Error: $e');
          Get.snackbar("Error", "Could not prepare image for editing");
          return;
        }
      }
    }

    debugPrint('[IMAGE EDIT] Final Path: $pathToEdit');

    if (pathToEdit == null || !File(pathToEdit!).existsSync()) {
      Get.snackbar("Error", "Image source not available");
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
      Get.snackbar("Error", "Could not open image editor");
    }
  }

  void _showDeleteMenu(BuildContext context) {
    if (controller.isReadOnly.value) return;

    Get.dialog(
      IOSActionMenu(
        type: IOSMenuType.popup,
        title: "Attachment Options",
        actions: [
          IOSMenuAction(
            label: "Edit Image",
            icon: CupertinoIcons.pencil,
            onTap: () {
              Get.back();
              _openImageEditor(context);
            },
          ),
          IOSMenuAction(
            label: "Delete Picture",
            icon: CupertinoIcons.trash,
            isDestructive: true,
            onTap: () {
              Get.back();
              controller.deleteBlock(blockIndex);
            },
          ),
        ],
      ),
      barrierColor: Colors.black.withValues(alpha: 0.2),
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

    path = path.trim();
    if (path.startsWith('[') && path.endsWith(']')) {
      path = path.substring(1, path.length - 1).trim();
    }
    if (path.startsWith('(') && path.endsWith(')')) {
      path = path.substring(1, path.length - 1).trim();
    }

    final match = RegExp(r'(/[^)\]\s]+\.[\w\d]+)').firstMatch(path);
    if (match != null) {
      path = match.group(0)!;
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
