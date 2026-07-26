import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'folder_controller.dart';
import '../../app/theme/colors.dart';
import '../../app/routes/app_routes.dart';
import '../../core/widgets/note_card.dart';
import '../../core/widgets/sort_filter_sheets.dart';
import '../../data/models/folder_model.dart';

class FolderDetailView extends GetView<FolderController> {
  const FolderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final folder = args?['folder'] as FolderModel?;
    final heroTag = args?['heroTag'] as String?;

    if (folder != null && controller.selectedFolder.value?.id != folder.id) {
      controller.selectFolder(folder, navigate: false);
    }

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Column(
          children: [
            Text(controller.selectedFolder.value?.name ?? 'Folder'),
            Text(
              '${controller.folderNotes.length} Notes',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        )),
        actions: [
          IconButton(
            onPressed: () => Get.bottomSheet(const SortSheet()), 
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: () => Get.bottomSheet(const FilterSheet()), 
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Hero(
          tag: heroTag ?? 'folder_selected',
          child: Material(
            color: Colors.transparent,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: controller.folderNotes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => NoteCard(
                note: controller.folderNotes[index],
                onTap: () => Get.toNamed(AppRoutes.noteEditor, arguments: controller.folderNotes[index].id),
              ),
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'folder_detail_fab',
        onPressed: () => Get.toNamed(AppRoutes.noteEditor),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
