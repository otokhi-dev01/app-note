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
          IconButton(
            tooltip: 'Share',
            onPressed: _shareImage,
            icon: const Icon(CupertinoIcons.share),
          ),
          if (widget.canEdit)
            TextButton(
              onPressed: _openProEditor,
              child: const Text(
                'Edit',
                style: TextStyle(color: AppTheme.folderYellow, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
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
                  Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Text("Image not available", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _shareImage() {
    Get.dialog(
      AlertDialog(
        title: const Text("Share Image"),
        content: const Text("Sharing options will be available soon."),
        actions: [TextButton(onPressed: () => Get.back(), child: const Text("OK"))],
      ),
    );
  }

  Future<void> _openProEditor() async {
    if (_isSaving) return;

    final configs = ProImageEditorConfigs(
      designMode: ImageEditorDesignMode.cupertino,
      theme: Theme.of(context).copyWith(
        primaryColor: AppTheme.folderYellow,
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: AppTheme.folderYellow),
      ),
    );

    final callbacks = ProImageEditorCallbacks(
      onImageEditingComplete: (Uint8List bytes) async {
        if (_isSaving) return;
        setState(() => _isSaving = true);
        try {
          final directory = await getTemporaryDirectory();
          final path = '${directory.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(path);
          await file.writeAsBytes(bytes);
          
          if (mounted) {
            // Use a single pop with result if possible, but since ProImageEditor 
            // is a separate route, we pop it first then the preview.
            Get.back(); // Close editor
            Get.back(result: path); // Return path to note detail
          }
        } catch (e) {
          debugPrint('Error saving edited image: $e');
          Get.snackbar("Error", "Could not save edited image", snackPosition: SnackPosition.BOTTOM);
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      },
      onCloseEditor: (editorMode) => Get.back(),
    );

    try {
      if (widget.localPath != null && File(widget.localPath!).existsSync()) {
        Get.to(() => ProImageEditor.file(
          File(widget.localPath!),
          configs: configs,
          callbacks: callbacks,
        ));
      } else if (widget.url != null && widget.url!.isNotEmpty) {
        // Pre-verify network image to avoid crash in editor
        final response = await HttpClient().getUrl(Uri.parse(widget.url!))
            .then((request) => request.close())
            .timeout(const Duration(seconds: 5));
            
        if (response.statusCode != 200) {
          throw Exception("Image not reachable (Status: ${response.statusCode})");
        }

        Get.to(() => ProImageEditor.network(
          widget.url!,
          configs: configs,
          callbacks: callbacks,
        ));
      } else {
        throw Exception("Image source not available");
      }
    } catch (e) {
      Get.snackbar(
        "Error", 
        "Could not open image for editing: ${e.toString().contains("404") ? "Not found" : "Connection error"}", 
        snackPosition: SnackPosition.BOTTOM
      );
    }
  }
}
