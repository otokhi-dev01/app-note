import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/note_model.dart';
import '../note/note_list_controller.dart';
import '../../app/theme/colors.dart';
import '../../app/routes/app_routes.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/custom_app_bar.dart';

class ArchiveView extends StatelessWidget {
  const ArchiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NoteListController>() 
      ? Get.find<NoteListController>() 
      : Get.put(NoteListController());
    controller.fetchArchivedNotes();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: CustomGlassAppBar(
        titleText: 'Archive',
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.search),
            icon: const Icon(Icons.search_rounded, weight: 800),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Text(
              'Items here are hidden from your main notes view but remain searchable. They stay indefinitely.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.notes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.notes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined, size: 80, color: AppColors.textPlaceholder.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('Archive is empty', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: controller.notes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _buildArchiveCard(controller, controller.notes[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveCard(NoteListController controller, NoteModel note) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Get.toNamed(AppRoutes.noteEditor, arguments: note.id),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 24, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title.isEmpty ? 'Untitled Note' : note.title, 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note.content?.firstWhereOrNull((b) => b.type == 'text')?.text ?? 'No description available',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildBadge('Archived ${controller.getTimeAgo(note.updatedAt)}', const Color(0xFFF1F5F9), const Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    if (note.folderName != null)
                      _buildBadge(note.folderName!, const Color(0xFFF0FDFA), const Color(0xFF0D9488)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      onPressed: () => controller.archiveNote(note, false),
                      icon: Icons.unarchive_outlined,
                      label: 'Restore',
                      color: const Color(0xFF1E293B),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () async {
                        final confirm = await UIHelpers.showConfirmDialog(
                          title: 'Delete Permanently',
                          message: 'Are you sure?',
                          confirmText: 'Delete',
                        );
                        if (confirm == true) {
                          controller.deleteNoteForever(note.id!);
                        }
                      },
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton({required VoidCallback onPressed, required IconData icon, required String label, required Color color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
