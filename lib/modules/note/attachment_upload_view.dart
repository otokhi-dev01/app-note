import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otokhi_note/core/widgets/liquid_glass_container.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/custom_app_bar.dart';
import 'note_controller.dart';

class AttachmentUploadView extends GetView<NoteController> {
  const AttachmentUploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomGlassAppBar(
        titleText: 'Upload',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, size: 32, color: AppColors.accent),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap to upload',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'or drag and drop files here\nPDF, PNG, JPG or DOC up to 50MB',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Select Files',
              onPressed: controller.addFileBlock,
            ),
            const SizedBox(height: 40),
            const Text(
              'RECENTLY UPLOADED',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final attachments = controller.note.value?.attachments ?? [];
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attachments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final attachment = attachments[index];
                  final sizeStr = (attachment.sizeBytes / 1024 / 1024).toStringAsFixed(1) + ' MB';
                  return _buildFileItem(
                    attachment.originalFileName, 
                    sizeStr,
                    onDelete: () => controller.deleteAttachment(attachment.id),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(String name, String size, {VoidCallback? onDelete}) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          LiquidGlassContainer(
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.description_outlined, fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(size, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, fontWeight: FontWeight.bold, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
