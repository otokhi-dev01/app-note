import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'note_list_controller.dart';
import '../../app/theme/colors.dart';
import '../../data/models/note_model.dart';

class PinnedNotesView extends StatelessWidget {
  const PinnedNotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NoteListController>();
    controller.fetchPinnedNotes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinned Notes'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          const CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://i.pravatar.cc/150')),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(() => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: controller.notes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildPinnedCard(controller, controller.notes[index]),
      )),
    );
  }

  Widget _buildPinnedCard(NoteListController controller, NoteModel note) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(note.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => controller.togglePin(note),
                icon: const Icon(Icons.push_pin, size: 20, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Focus on increasing brand awareness in key demographics. Reallocate budget towards influencer partnerships and...',
            maxLines: 3,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildTag('Work', Colors.teal),
                  const SizedBox(width: 8),
                  _buildTag('Planning', Colors.orange),
                ],
              ),
              const Text('Oct 12', style: TextStyle(fontSize: 12, color: AppColors.textPlaceholder)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
