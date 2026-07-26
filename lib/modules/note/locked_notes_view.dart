import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'note_list_controller.dart';
import '../../app/theme/colors.dart';
import '../../data/models/note_model.dart';

class LockedNotesView extends StatelessWidget {
  const LockedNotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NoteListController>() 
      ? Get.find<NoteListController>() 
      : Get.put(NoteListController());
    controller.fetchLockedNotes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locked Notes'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(() => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: controller.notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildLockedCard(controller.notes[index]),
      )),
    );
  }

  Widget _buildLockedCard(NoteModel note) {
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
              const Icon(Icons.lock, size: 20, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This note is locked and requires a PIN or biometrics to view.',
            style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: const Text('Private', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Text('Oct 12', style: TextStyle(fontSize: 12, color: AppColors.textPlaceholder)),
            ],
          ),
        ],
      ),
    );
  }
}
