import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/colors.dart';
import 'note_controller.dart';
import 'attachment_upload_view.dart';
import 'attachment_preview_view.dart';

class AttachmentListView extends GetView<NoteController> {
  const AttachmentListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Attachments'),
            Text(
              controller.note.value?.title ?? 'Project_Alpha_Notes',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UPLOADED FILES',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.blocks.where((b) => b.type == 'attachment').length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final attachment = controller.blocks.where((b) => b.type == 'attachment').toList()[index];
                      return _buildAttachmentCard(
                        attachment.displayName ?? 'File', 
                        '2.4 MB', 
                        'Document',
                        onTap: () => Get.to(() => AttachmentPreviewView(fileName: attachment.displayName ?? 'File')),
                      );
                    },
                  )),
                ],
              ),
            ),
          ),
          _buildUploadPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(String name, String size, String type, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insert_drive_file, color: AppColors.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('$size • $type', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.delete_outline, color: AppColors.textPlaceholder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: InkWell(
        onTap: () => Get.to(() => const AttachmentUploadView()),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.upload, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              const Text('Upload Attachment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Drag & drop or tap to browse', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
