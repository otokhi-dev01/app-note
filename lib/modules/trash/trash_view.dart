import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../note/note_list_controller.dart';
import '../../app/theme/colors.dart';
import '../../data/models/note_model.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/liquid_glass_container.dart';
import 'package:intl/intl.dart';

class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NoteListController>() 
      ? Get.find<NoteListController>() 
      : Get.put(NoteListController());
    controller.fetchTrashNotes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final confirm = await UIHelpers.showConfirmDialog(
                title: 'Clear Trash',
                message: 'Are you sure you want to permanently delete all items in trash?',
                confirmText: 'Clear All',
              );
              if (confirm == true) {
                controller.clearAllTrash();
              }
            },
            icon: const Icon(Icons.delete_forever, size: 18, color: AppColors.error),
            label: const Text('Clear Trash', style: TextStyle(color: AppColors.error)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Items in trash will be permanently deleted after 30 days.',
              style: TextStyle(color: AppColors.textSecondary),
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
                      Icon(Icons.delete_outline, size: 64, color: AppColors.textPlaceholder.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('Trash is empty', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: controller.notes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _buildTrashCard(controller, controller.notes[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashCard(NoteListController controller, NoteModel note) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note.title, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('In Trash', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content?.firstWhereOrNull((b) => b.type == 'text')?.text ?? 'No description available',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deleted: ${note.deletedAt != null ? DateFormat('MMM dd').format(note.deletedAt!) : 'Recently'}', 
                style: const TextStyle(fontSize: 12, color: AppColors.textPlaceholder),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => controller.restoreNote(note.id!),
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Restore'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final confirm = await UIHelpers.showConfirmDialog(
                        title: 'Delete Forever',
                        message: 'Are you sure you want to delete this note permanently?',
                        confirmText: 'Delete',
                      );
                      if (confirm == true) {
                        controller.deleteNoteForever(note.id!);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
