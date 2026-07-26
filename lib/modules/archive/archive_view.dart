import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../note/note_list_controller.dart';
import '../../app/theme/colors.dart';
import '../../data/models/note_model.dart';

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.archive_outlined, size: 20, color: AppColors.textPlaceholder),
              const SizedBox(width: 8),
              Text(note.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Initial thoughts on the new architecture. We need to focus on scalability...',
            maxLines: 2,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: const Text('Archived 2 weeks ago', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Work', style: TextStyle(fontSize: 10, color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Restore'),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, color: AppColors.error)),
            ],
          ),
        ],
      ),
    );
  }
}
