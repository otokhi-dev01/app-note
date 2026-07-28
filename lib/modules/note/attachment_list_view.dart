import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/colors.dart';
import '../../data/models/attachment_model.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/custom_app_bar.dart';
import 'note_controller.dart';
import 'attachment_upload_view.dart';
import 'attachment_preview_view.dart';

class AttachmentListView extends GetView<NoteController> {
  const AttachmentListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: CustomGlassAppBar(
        title: Column(
          children: [
            const Text(
              'Attachments', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
            ),
            Obx(() => Text(
              controller.note.value?.title ?? 'Untitled Note',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
            )),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UPLOADED FILES',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final attachments = controller.note.value?.attachments ?? [];
                    if (attachments.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Column(
                            children: [
                              Icon(Icons.attachment_rounded, size: 48, color: const Color(0xFFE2E8F0)),
                              const SizedBox(height: 12),
                              const Text('No attachments found', style: TextStyle(color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: attachments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildAttachmentCard(attachments[index]);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          _buildUploadPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(AttachmentModel attachment) {
    final String size = (attachment.sizeBytes / 1024 / 1024).toStringAsFixed(1);
    final isImage = attachment.mimeType.startsWith('image/');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => AttachmentPreviewView(fileName: attachment.originalFileName)),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            'https://note.piisiit.com${attachment.filePath}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Color(0xFF94A3B8)),
                          ),
                        )
                      : const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF64748B), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.originalFileName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$size MB • ${attachment.mimeType.split('/').last.toUpperCase()}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.deleteAttachment(attachment.id),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () => Get.to(() => const AttachmentUploadView()),
          child: LiquidGlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(20),
            opacity: 0.1,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                  child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 12),
                const Text('Upload New Attachment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                const Text('Images, PDFs or Documents up to 10MB', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
