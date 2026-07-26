import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'folder_controller.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/folder_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/folder_model.dart';

class FolderListView extends GetView<FolderController> {
  const FolderListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: Obx(() => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: controller.folders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final folder = controller.folders[index];
          final heroTag = 'list_folder_${folder.id ?? index}';
          return TweenAnimationBuilder(
            duration: Duration(milliseconds: 400 + (index * 50)),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: child,
              ),
            ),
            child: Hero(
              tag: heroTag,
              child: FolderCard(
                folder: folder,
                isGrid: false,
                onTap: () => controller.selectFolder(folder),
              ),
            ),
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        heroTag: 'folder_fab',
        onPressed: () => _showCreateFolderSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateFolderSheet(BuildContext context, {FolderModel? editFolder}) {
    if (editFolder != null) {
      controller.nameController.text = editFolder.name;
    } else {
      controller.nameController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(editFolder != null ? 'Edit Folder' : 'New Folder', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            AppTextField(
              label: '',
              hint: 'e.g. Travel Plans',
              controller: controller.nameController,
              prefixIcon: const Icon(Icons.folder_open_outlined),
            ),
            const SizedBox(height: 24),
            const Text('COLOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppColors.folderColors.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => Obx(() => GestureDetector(
                  onTap: () => controller.selectedColorIndex.value = index,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.folderColors[index],
                      shape: BoxShape.circle,
                      border: controller.selectedColorIndex.value == index 
                        ? Border.all(color: AppColors.primary, width: 2) 
                        : null,
                    ),
                    child: controller.selectedColorIndex.value == index 
                      ? const Icon(Icons.check, color: Colors.white, size: 20) 
                      : null,
                  ),
                )),
              ),
            ),
            const SizedBox(height: 24),
            const Text('ICON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildIconOption(Icons.folder, 0),
                  _buildIconOption(Icons.work, 1),
                  _buildIconOption(Icons.home, 2),
                  _buildIconOption(Icons.lightbulb, 3),
                  _buildIconOption(Icons.favorite, 4),
                  _buildIconOption(Icons.school, 5),
                ],
              ),
            ),
            const SizedBox(height: 40),
            AppButton(
              onPressed: controller.createFolder,
              text: editFolder != null ? 'Update Folder' : 'Create Folder',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIconOption(IconData icon, int index) {
    return Obx(() => GestureDetector(
      onTap: () => controller.selectedIconIndex.value = index,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: controller.selectedIconIndex.value == index ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: controller.selectedIconIndex.value == index 
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] 
            : null,
        ),
        child: Icon(icon, color: controller.selectedIconIndex.value == index ? AppColors.primary : AppColors.textSecondary),
      ),
    ));
  }
}
