import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'folder_controller.dart';
import '../../app/theme/colors.dart';
import '../../app/routes/app_routes.dart';
import '../../core/widgets/note_card.dart';
import '../../core/widgets/sort_filter_sheets.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../data/models/folder_model.dart';

class FolderDetailView extends StatefulWidget {
  const FolderDetailView({super.key});

  @override
  State<FolderDetailView> createState() => _FolderDetailViewState();
}

class _FolderDetailViewState extends State<FolderDetailView> with AutomaticKeepAliveClientMixin {
  final controller = Get.find<FolderController>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final args = Get.arguments as Map<String, dynamic>?;
    final folder = args?['folder'] as FolderModel?;
    final heroTag = args?['heroTag'] as String?;

    if (folder != null && controller.selectedFolder.value?.id != folder.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selectFolder(folder, navigate: false);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: CustomGlassAppBar(
        title: Obx(() => Column(
          children: [
            Text(
              controller.selectedFolder.value?.name ?? 'Folder',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 18, 
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.primary
              ),
            ),
            Text(
              '${controller.folderNotes.length} Notes',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        )),
        actions: [
          IconButton(
            onPressed: () => Get.bottomSheet(const SortSheet()), 
            icon: const Icon(Icons.sort_rounded),
          ),
          IconButton(
            onPressed: () => Get.bottomSheet(const FilterSheet()), 
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.folderNotes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.folderNotes.isEmpty && !controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_alt_outlined, size: 64, color: AppColors.textPlaceholder.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text('No notes in this folder', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return Hero(
          tag: heroTag ?? 'folder_selected_${controller.selectedFolder.value?.id}',
          child: Material(
            color: Colors.transparent,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              itemCount: controller.folderNotes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = controller.folderNotes[index];
                return NoteCard(
                  note: note,
                  onTap: () => Get.toNamed(AppRoutes.noteEditor, arguments: note.id),
                );
              },
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'folder_detail_fab',
        onPressed: () => Get.toNamed(AppRoutes.noteEditor, arguments: {'folderId': controller.selectedFolder.value?.id}),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.open_in_new),
      ),
    );
  }
}
