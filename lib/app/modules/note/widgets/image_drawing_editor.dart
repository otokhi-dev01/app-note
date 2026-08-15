import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ios_image_editor/ios_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart' as dio;
import '../../../theme/app_theme.dart';

class ImageDrawingEditor extends StatefulWidget {
  final String? localPath;
  final String? url;
  final ImageProvider imageProvider;
  final String title;
  final bool canEdit;
  final bool startWithPencil;

  const ImageDrawingEditor({
    super.key,
    this.localPath,
    this.url,
    required this.imageProvider,
    this.title = 'Image Preview',
    this.canEdit = true,
    this.startWithPencil = false,
  });

  @override
  State<ImageDrawingEditor> createState() => _ImageDrawingEditorState();
}

class _ImageDrawingEditorState extends State<ImageDrawingEditor> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.startWithPencil && widget.canEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openNativeEditor();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: [
          if (widget.canEdit)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Edit Image',
              onPressed: _openNativeEditor,
              icon: const Icon(
                CupertinoIcons.square_pencil,
                color: AppTheme.folderPink,
                size: 24,
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Image(
                image: widget.imageProvider,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Image not available",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isSaving)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.folderPink),
            ),
        ],
      ),
    );
  }

  Future<void> _openNativeEditor() async {
    if (_isSaving) return;

    String? pathToEdit = widget.localPath;

    setState(() => _isSaving = true);

    try {
      // 1. Prepare local path if it's a network URL
      if (pathToEdit == null || !File(pathToEdit).existsSync()) {
        if (widget.url != null && widget.url!.isNotEmpty) {
          final directory = await getTemporaryDirectory();
          pathToEdit = '${directory.path}/temp_${DateTime.now().millisecondsSinceEpoch}.png';
          await dio.Dio().download(widget.url!, pathToEdit);
        }
      }

      if (pathToEdit == null || !File(pathToEdit).existsSync()) {
        throw Exception("Image source not available");
      }

      // 2. Open native iOS Markup editor
      final String? editedPath = await IOSImageEditor.editImage(pathToEdit);

      if (editedPath != null && mounted) {
        // Success: return the path to the previous screen (NoteDetailController)
        Get.back(result: editedPath);
      }
    } catch (e) {
      debugPrint('Error editing image: $e');
      if (mounted) {
        Get.snackbar("Error", "Could not open editor or save image");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
