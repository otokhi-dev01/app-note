import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import '../../../theme/app_theme.dart';

class ImageDrawingEditor extends StatefulWidget {
  final String? localPath;
  final String? url;
  final ImageProvider imageProvider;
  final String title;
  final bool canEdit;

  const ImageDrawingEditor({
    super.key,
    this.localPath,
    this.url,
    required this.imageProvider,
    this.title = 'Image Preview',
    this.canEdit = true,
  });

  @override
  State<ImageDrawingEditor> createState() => _ImageDrawingEditorState();
}

class _ImageDrawingEditorState extends State<ImageDrawingEditor> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.canEdit)
            IconButton(
              tooltip: 'Edit Image',
              onPressed: _openProEditor,
              icon: const Icon(
                CupertinoIcons.pencil_outline,
                color: AppTheme.folderPink,
              ),
            ),
          IconButton(
            tooltip: 'Share',
            onPressed: _shareImage,
            icon: const Icon(CupertinoIcons.share),
          ),
          const SizedBox(width: 8),
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

  void _shareImage() {
    Get.snackbar(
      "Info",
      "Sharing options will be available soon.",
      colorText: Colors.white,
    );
  }

  Future<void> _openProEditor() async {
    if (_isSaving) return;

    final configs = ProImageEditorConfigs(
      designMode: ImageEditorDesignMode.cupertino,
      theme: Theme.of(context).copyWith(
        primaryColor: AppTheme.folderPink,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: AppTheme.folderPink,
        ),
      ),
      i18n: const I18n(done: 'Save', cancel: 'Cancel'),
    );

    final callbacks = ProImageEditorCallbacks(
      onImageEditingComplete: (Uint8List bytes) async {
        setState(() => _isSaving = true);
        try {
          final directory = await getTemporaryDirectory();
          final path =
              '${directory.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(path);
          await file.writeAsBytes(bytes);

          if (mounted) {
            // Success: Close the pro editor and return the path to the previous screen
            Get.back(); // Pop ProImageEditor
            Get.back(
              result: path,
            ); // Pop Preview and return path to NoteDetailController
          }
        } catch (e) {
          debugPrint('Error saving edited image: $e');
          Get.snackbar("Error", "Could not save edited image");
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      },
      onCloseEditor: (editorMode) => Get.back(),
    );

    try {
      if (widget.localPath != null && File(widget.localPath!).existsSync()) {
        Get.to(
          () => ProImageEditor.file(
            File(widget.localPath!),
            configs: configs,
            callbacks: callbacks,
          ),
        );
      } else if (widget.url != null && widget.url!.isNotEmpty) {
        // Pre-verify network image
        Get.to(
          () => ProImageEditor.network(
            widget.url!,
            configs: configs,
            callbacks: callbacks,
          ),
        );
      } else {
        throw Exception("Image source not available");
      }
    } catch (e) {
      Get.snackbar("Error", "Could not open editor");
    }
  }
}
