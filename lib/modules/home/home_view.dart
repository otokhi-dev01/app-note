import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../../app/theme/colors.dart';
import '../../app/routes/app_routes.dart';
import '../../core/widgets/folder_card.dart';
import '../../core/widgets/note_card.dart';
import '../../core/widgets/sort_filter_sheets.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/keep_alive_wrapper.dart';
import '../folder/folder_list_view.dart';
import '../note/pinned_notes_view.dart';
import '../settings/settings_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        key: const ValueKey('home_page_view'),
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: [
          const KeepAliveWrapper(child: _DashboardView()),
          const KeepAliveWrapper(child: FolderListView()),
          const KeepAliveWrapper(child: PinnedNotesView()),
          const KeepAliveWrapper(child: SettingsView()),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: LiquidGlassContainer(
          borderRadius: BorderRadius.circular(30),
          blur: 20,
          opacity: 0.6,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.description_outlined,
                  activeIcon: Icons.description,
                  label: 'Notes',
                  isSelected: controller.currentIndex.value == 0,
                  onTap: () => controller.changePage(0),
                ),
                _NavBarItem(
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder,
                  label: 'Folders',
                  isSelected: controller.currentIndex.value == 1,
                  onTap: () => controller.changePage(1),
                ),
                _NavBarItem(
                  icon: Icons.push_pin_outlined,
                  activeIcon: Icons.push_pin,
                  label: 'Pinned',
                  isSelected: controller.currentIndex.value == 2,
                  onTap: () => controller.changePage(2),
                ),
                _NavBarItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  isSelected: controller.currentIndex.value == 3,
                  onTap: () => controller.changePage(3),
                ),
              ],
            )),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          heroTag: 'home_fab',
          onPressed: () => Get.toNamed(AppRoutes.noteEditor),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, size: 28, color: Colors.white, weight: 800),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: isSelected ? 1.2 : 1.0,
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.6),
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            child: Text(label),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            width: isSelected ? 4 : 0,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ],
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
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 160.0),
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
          height: 180,
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
          itemCount: controller.folders.take(4).length,
            itemBuilder: (context, index) {
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
          },
        )),
      ],
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
