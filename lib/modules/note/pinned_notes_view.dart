import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'note_list_controller.dart';
import '../../app/theme/colors.dart';
import '../../app/routes/app_routes.dart';
import '../../core/widgets/note_card.dart';

class PinnedNotesView extends StatelessWidget {
  const PinnedNotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NoteListController>();
    controller.fetchPinnedNotes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinned Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.fetchPinnedNotes(),
        child: Obx(() {
          if (controller.isLoading.value && controller.notes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.push_pin_outlined, size: 64, color: AppColors.textPlaceholder.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No Pinned Notes', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            itemCount: controller.notes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final note = controller.notes[index];
              return NoteCard(
                note: note,
                isPinned: true,
                onTap: () => Get.toNamed(AppRoutes.noteEditor, arguments: note.id),
              );
            },
          );
        }),
      ),
    );
  }
}
