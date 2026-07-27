import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/note_model.dart';
import '../note/note_list_controller.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/liquid_glass_container.dart';

class ArchiveView extends StatelessWidget {
  const ArchiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NoteListController>() 
      ? Get.find<NoteListController>() 
      : Get.put(NoteListController());
    controller.fetchArchivedNotes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          const CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://i.pravatar.cc/150')),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Items here are hidden from your main notes view but remain searchable. They stay indefinitely.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Obx(() => ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: controller.notes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildArchiveCard(controller.notes[index]),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveCard(NoteModel note) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.archive_outlined, size: 20, color: AppColors.textPlaceholder),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.title, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content?.firstWhereOrNull((b) => b.type == 'text')?.text ?? 'No description',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.4), 
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Archived recently', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note.folderName ?? 'General', 
                  style: const TextStyle(fontSize: 10, color: AppColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => Get.find<NoteListController>().archiveNote(note, false),
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Restore'),
              ),
              IconButton(
                onPressed: () => Get.find<NoteListController>().deleteNoteForever(note.id!), 
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
