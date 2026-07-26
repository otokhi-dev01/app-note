import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/colors.dart';

class AttachmentPreviewView extends StatelessWidget {
  final String fileName;
  const AttachmentPreviewView({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(fileName, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 40),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20)),
                ],
              ),
              child: Column(
                children: [
                  const Text('Attachment Preview', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  // Mocking the PDF view from image 2
                  Image.network(
                    'https://note.piisiit.com/uploads/placeholder_doc.png',
                    height: 400,
                    errorBuilder: (_, __, ___) => const Icon(Icons.insert_drive_file, size: 200, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            // Floating zoom controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left, color: AppColors.textPlaceholder),
                  const SizedBox(width: 16),
                  const Text('1 / 24', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  const Icon(Icons.chevron_right, color: AppColors.textPlaceholder),
                  const SizedBox(width: 16),
                  const VerticalDivider(),
                  const SizedBox(width: 16),
                  const Icon(Icons.zoom_out),
                  const SizedBox(width: 24),
                  const Icon(Icons.zoom_in),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
