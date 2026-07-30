import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'folder_controller.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/folder_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/decorative_background.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../data/models/folder_model.dart';

class FolderListView extends StatefulWidget {
  const FolderListView({super.key});

  @override
  State<FolderListView> createState() => _FolderListViewState();
}

class _FolderListViewState extends State<FolderListView>
    with AutomaticKeepAliveClientMixin {
  final controller = Get.find<FolderController>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecorativeBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // iOS-Style Collapsing Header
            CustomGlassSliverAppBar(
              titleText: 'Folders',
              expandedHeight: 120.0,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(30),
                bottomLeft: Radius.circular(30),
              ),
              actions: [
                Obx(
                  () => IconButton(
                    onPressed: controller.toggleViewMode,
                    icon: Icon(
                      controller.isGridView.value
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: isDark ? Colors.white : AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showCreateFolderDialog(context),
                  icon: Icon(
                    Icons.open_in_new,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(0),
                child: SizedBox(),
              ),
            ),
            // Pull-to-Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: LiquidGlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  opacity: 0.6,
                  child: TextField(
                    onChanged: controller.updateSearchQuery,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Search all notes...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white38
                            : AppColors.textPlaceholder,
                        fontWeight: FontWeight.bold,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 22,
                        color: isDark
                            ? Colors.white38
                            : AppColors.textPlaceholder,
                        weight: 800,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            // Dynamic Folder Content (Grid or List)
            Obx(() {
              final folders = controller.filteredFolders;
              if (folders.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 64,
                          color: isDark ? Colors.white10 : AppColors.border,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No folders found',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (controller.isGridView.value) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final folder = folders[index];
                      return FolderCard(
                        folder: folder,
                        isGrid: true,
                        onTap: () => controller.selectFolder(folder),
                        onEdit: () => _showCreateFolderDialog(
                          context,
                          editFolder: folder,
                        ),
                        onDelete: () =>
                            _showDeleteConfirmation(context, folder),
                      );
                    }, childCount: folders.length),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final folder = folders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FolderCard(
                        folder: folder,
                        isGrid: false,
                        onTap: () => controller.selectFolder(folder),
                        onEdit: () => _showCreateFolderDialog(
                          context,
                          editFolder: folder,
                        ),
                        onDelete: () =>
                            _showDeleteConfirmation(context, folder),
                      ),
                    );
                  }, childCount: folders.length),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog(
    BuildContext context, {
    FolderModel? editFolder,
  }) {
    if (editFolder != null) {
      controller.openEditFolder(editFolder);
    } else {
      controller.selectedFolder.value = null;
      controller.nameController.clear();
      controller.selectedColorIndex.value = 0;
      controller.selectedIconIndex.value = 0;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: LiquidGlassContainer(
          borderRadius: BorderRadius.circular(30),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      editFolder != null ? 'Edit Folder' : 'New Folder',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'NAME',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  label: '',
                  hint: 'e.g. Travel Plans',
                  controller: controller.nameController,
                  prefixIcon: Icon(
                    Icons.folder_open_outlined,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'COLOR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppColors.folderColors.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) => Obx(
                      () => GestureDetector(
                        onTap: () =>
                            controller.selectedColorIndex.value = index,
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
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ICON',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
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
                      _buildIconOption(Icons.work_outline, 1),
                      _buildIconOption(Icons.home_outlined, 2),
                      _buildIconOption(Icons.lightbulb_outline, 3),
                      _buildIconOption(Icons.favorite_border, 4),
                      _buildIconOption(Icons.school_outlined, 5),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AppButton(
                  onPressed: controller.createFolder,
                  text: editFolder != null ? 'Update Folder' : 'Create Folder',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FolderModel folder) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: LiquidGlassContainer(
          borderRadius: BorderRadius.circular(30),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Folder',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${folder.name}"? All notes in this folder will be moved to Trash.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (folder.id != null) {
                          controller.deleteFolder(folder.id!);
                        }
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconOption(IconData icon, int index) {
    return Obx(
      () => GestureDetector(
        onTap: () => controller.selectedIconIndex.value = index,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: controller.selectedIconIndex.value == index
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: controller.selectedIconIndex.value == index
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: controller.selectedIconIndex.value == index
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
