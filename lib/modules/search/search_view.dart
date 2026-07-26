import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../note/note_list_controller.dart';
import '../../app/theme/colors.dart';
import '../../data/models/note_model.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NoteListController());

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: controller.searchNotes,
          decoration: const InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('RECENT SEARCHES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 12,
              children: [
                _buildSearchTag('Q3 planning'),
                _buildSearchTag('meeting notes'),
                _buildSearchTag('ideas'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() => ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: controller.notes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildResultCard(controller.notes[index]),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildResultCard(NoteModel note) {
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
              const Icon(Icons.folder_outlined, size: 16, color: AppColors.textPlaceholder),
              const SizedBox(width: 4),
              Text(note.folderName ?? 'Work', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              const CircleAvatar(radius: 2, backgroundColor: AppColors.textPlaceholder),
              const SizedBox(width: 8),
              const Text('2 days ago', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(note.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              children: [
                const TextSpan(text: 'Initial thoughts on the Alpha '),
                TextSpan(text: 'project', style: TextStyle(backgroundColor: AppColors.accent.withValues(alpha: 0.3), color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                const TextSpan(text: ' timeline. We need to align the design system with the...'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
