import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../../app/theme/colors.dart';
import '../../app/routes/app_routes.dart';
import '../../core/widgets/folder_card.dart';
import '../../core/widgets/note_card.dart';
import '../../core/widgets/sort_filter_sheets.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../folder/folder_list_view.dart';
import '../note/pinned_notes_view.dart';
import '../settings/settings_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: const [
          _DashboardView(),
          FolderListView(),
          PinnedNotesView(),
          SettingsView(),
        ],
      )),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: LiquidGlassContainer(
          borderRadius: BorderRadius.circular(30),
          blur: 20,
          opacity: 0.6,
          child: Obx(() => BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changePage,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.textSecondary.withValues(alpha: 0.5),
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Notes', activeIcon: Icon(Icons.description)),
              BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Folders', activeIcon: Icon(Icons.folder)),
              BottomNavigationBarItem(icon: Icon(Icons.push_pin_outlined), label: 'Pinned', activeIcon: Icon(Icons.push_pin)),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings', activeIcon: Icon(Icons.settings)),
            ],
          )),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () => Get.toNamed(AppRoutes.noteEditor),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DashboardView extends GetView<HomeController> {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.fetchData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 120.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildPinnedNotes(),
              const SizedBox(height: 32),
              _buildFoldersGrid(),
              const SizedBox(height: 32),
              _buildRecentNotes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final user = controller.user.value;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good morning,', style: TextStyle(color: AppColors.textSecondary)),
              Text(
                user?.fullName ?? 'Welcome',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.profile),
            child: Hero(
              tag: 'profile_avatar',
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: LiquidGlassContainer(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            opacity: 0.6,
            child: TextField(
              onTap: () => Get.toNamed(AppRoutes.search),
              readOnly: true,
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: 'Search notes, folders...',
                prefixIcon: Icon(Icons.search, color: AppColors.textPlaceholder),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        LiquidGlassContainer(
          borderRadius: BorderRadius.circular(16),
          child: IconButton(
            onPressed: () => Get.bottomSheet(const FilterSheet()),
            icon: const Icon(Icons.tune_rounded, color: AppColors.accent),
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedNotes() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pinned Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.pinned),
              child: const Text('View all', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: Obx(() => ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.pinnedNotes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) => TweenAnimationBuilder(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(50 * (1 - value), 0),
                  child: child,
                ),
              ),
              child: NoteCard(
                note: controller.pinnedNotes[index],
                isPinned: true,
                onTap: () => Get.toNamed(AppRoutes.noteEditor, arguments: controller.pinnedNotes[index].id),
              ),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildFoldersGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Folders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => Get.toNamed(AppRoutes.folderList),
              icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: controller.folders.take(4).length + 1,
            itemBuilder: (context, index) {
            if (index < controller.folders.take(4).length) {
              final folder = controller.folders[index];
              final heroTag = 'home_folder_${folder.id ?? index}';
              return Hero(
                tag: heroTag,
                child: FolderCard(
                  folder: folder,
                  onTap: () => Get.toNamed(AppRoutes.folderDetail, arguments: {
                    'folder': folder,
                    'heroTag': heroTag,
                  }),
                ),
              );
            }
            return _buildNewFolderCard();
          },
        )),
      ],
    );
  }

  Widget _buildNewFolderCard() {
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.folderList),
      child: LiquidGlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text('New Folder', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Obx(() => ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.recentNotes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => NoteCard(
            note: controller.recentNotes[index],
            onTap: () => Get.toNamed(AppRoutes.noteEditor, arguments: controller.recentNotes[index].id),
          ),
        )),
      ],
    );
  }
}
