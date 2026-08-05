import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/models/folder_model.dart';
import '../../routes/app_pages.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import 'folder_controller.dart';
import 'widgets/folder_create_modal.dart';
import 'widgets/folder_context_menu.dart';

class FolderView extends GetView<FolderController> {
  const FolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark 
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent) 
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true,
        extendBodyBehindAppBar: true,
        bottomNavigationBar: _buildBottomBar(context),
        body: RefreshIndicator(
          onRefresh: () => controller.fetchFolders(refresh: true),
          color: AppTheme.folderYellow,
          backgroundColor: theme.scaffoldBackgroundColor,
          edgeOffset: 140,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // SliverAppBar with Dynamic Title Transition (Large to Small)
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                expandedHeight: 140.0,
                elevation: 0,
                automaticallyImplyLeading: false,
                centerTitle: true,
                systemOverlayStyle: theme.brightness == Brightness.dark 
                    ? SystemUiOverlayStyle.light 
                    : SystemUiOverlayStyle.dark,
                // Centered small title (visible when collapsed)
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final double percentage = (constraints.maxHeight - kToolbarHeight) / (140.0 - kToolbarHeight);
                    final opacity = (1.0 - percentage).clamp(0.0, 1.0);
                    
                    return Opacity(
                      opacity: opacity > 0.8 ? 1.0 : 0.0,
                      child: Text(
                        "Folders",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                    );
                  },
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        LiquidGlassContainer(
                          width: 44,
                          height: 44,
                          borderRadius: 22,
                          child: IconButton(
                            onPressed: () => Get.bottomSheet(
                              FolderCreateModal(controller: controller),
                              isScrollControlled: true,
                            ),
                            icon: Icon(Icons.create_new_folder_outlined,
                                color: theme.colorScheme.onSurface, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(() => controller.isEditing.value
                            ? LiquidGlassContainer(
                                width: 44,
                                height: 44,
                                borderRadius: 22,
                                child: GestureDetector(
                                  onTap: controller.toggleEditing,
                                  child: Center(
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        // color: AppTheme.folderYellow,
                                      ),
                                      child: const Icon(Icons.check,
                                          color: AppTheme.textSecondary, size: 20, fontWeight: FontWeight.bold,),
                                    ),
                                  ),
                                ),
                              )
                            : LiquidGlassContainer(
                                height: 44,
                                borderRadius: 22,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: TextButton(
                                  onPressed: controller.toggleEditing,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Edit",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 16
                      , 5),
                  title: LayoutBuilder(
                    builder: (context, constraints) {
                      final double percentage = (constraints.maxHeight - kToolbarHeight) / (140.0 - kToolbarHeight);
                      return Opacity(
                        opacity: percentage.clamp(0.0, 1.0),
                        child: Text(
                          "Folders",
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.folderYellow)),
                    );
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      // iCloud Section
                      if (controller.iCloudFolders.isNotEmpty) ...[
                        _buildSectionHeader(context, "iCloud",
                            controller.isICloudExpanded, controller.toggleICloud),
                        Obx(() => controller.isICloudExpanded.value
                            ? _buildFolderGroup(context, controller.iCloudFolders)
                            : const SizedBox.shrink()),
                        const SizedBox(height: 24),
                      ],

                      // On My iPhone Section
                      _buildSectionHeader(
                          context,
                          "On My iPhone",
                          controller.isOnMyiPhoneExpanded,
                          controller.toggleOnMyiPhone),
                      Obx(() => controller.isOnMyiPhoneExpanded.value
                          ? _buildFolderGroup(context, controller.onMyiPhoneFolders,
                              includeRecentlyDeleted: true)
                          : const SizedBox.shrink()),

                      const SizedBox(height: 120), // Bottom padding
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, RxBool isExpanded, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            Obx(() => Icon(
                  isExpanded.value ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppTheme.folderYellow,
                  size: 28,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderGroup(BuildContext context, List<FolderModel> folders, {bool includeRecentlyDeleted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderRadius: 30,
        padding: EdgeInsets.zero,
        children: [
          if (includeRecentlyDeleted) ...[
            _buildAllNotesTile(context),
            const Divider(indent: 56, height: 1),
          ],
          for (int i = 0; i < folders.length; i++) ...[
            _buildFolderTile(context, folders[i]),
            const Divider(indent: 56, height: 1),
          ],
          if (includeRecentlyDeleted) ...[
            _buildArchiveTile(context),
            const Divider(indent: 56, height: 1),
            _buildRecentlyDeletedTile(context),
            const Divider(indent: 56, height: 1),
            _buildTrashTile(context),
            const Divider(indent: 56, height: 1),
            _buildProfileTile(context),
          ],
        ],
      ),
    );
  }
  Widget _buildAllNotesTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;

      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.NOTE_LIST, arguments: FolderModel(
            id: 0, // 0 usually means All Notes in this app's logic
            name: "All on My iphone",
            iconName: "folder",
            colorValue: "#FFB703",
            sortOrder: 0,
          )),
          leading: const Icon(Icons.folder_special_outlined, color: AppTheme.folderYellow, size: 30),
          title: Text("All on My iphone", style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${controller.allNotesCount.value}", style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 20),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFolderTile(BuildContext context, FolderModel folder) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;
      final isSystem = controller.isSystemFolder(folder);

      return Opacity(
        opacity: (isEditing && isSystem) ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: (isEditing && isSystem)
              ? null
              : () => Get.toNamed(Routes.NOTE_LIST, arguments: folder)?.then((value) => controller.fetchFolders()),
          leading: Icon(folder.icon, color: AppTheme.folderYellow, size: 30),
          title: Text(folder.name, style: theme.textTheme.bodyLarge),
          trailing: isEditing && !isSystem
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => Get.dialog(
                        FolderContextMenu(folder: folder, controller: controller),
                        barrierColor: Colors.black.withValues(alpha: 0.1),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.folderYellow, width: 1.5),
                        ),
                        child: const Icon(Icons.more_horiz, color: AppTheme.folderYellow, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.reorder, color: theme.colorScheme.onSurfaceVariant, size: 24),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${folder.noteCount}", style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 20),
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildRecentlyDeletedTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;

      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.RECENTLY_DELETED),
          leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.folderYellow, size: 30),
          title: Text("Recently Deleted", style: theme.textTheme.bodyLarge),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${controller.deletedCount.value}", style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 20),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildArchiveTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;

      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.ARCHIVE),
          leading: const Icon(Icons.archive_outlined, color: AppTheme.folderYellow, size: 30),
          title: Text("Archive", style: theme.textTheme.bodyLarge),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${controller.archivedCount.value}", style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 20),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildProfileTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;

      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.PROFILE),
          leading: LiquidGlassContainer(
            width: 40,
            height: 40,
            borderRadius: 10,
            opacity: 0.08,
            blur: 15,
            child: const Center(
              child: Icon(Icons.person_outline, color: AppTheme.folderYellow, size: 24),
            ),
          ),
          title: Text("Profile", style: theme.textTheme.bodyLarge),
          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 20),
        ),
      );
    });
  }

  Widget _buildTrashTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;

      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.TRASH),
          leading: LiquidGlassContainer(
            width: 40,
            height: 40,
            borderRadius: 10,
            opacity: 0.08,
            blur: 15,
            child: const Center(
              child: Icon(Icons.delete_sweep_rounded, color: AppTheme.folderYellow, size: 24),
            ),
          ),
          title: Text("Trash", style: theme.textTheme.bodyLarge),
          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 20),
        ),
      );
    });
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.SEARCH),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: theme.brightness == Brightness.dark ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text("Search", style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 17)),
                      ),
                      Icon(Icons.mic, color: theme.colorScheme.onSurfaceVariant, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            LiquidGlassContainer(
              width: 50,
              height: 50,
              borderRadius: 25,
              child: IconButton(
                onPressed: () => controller.createNewNote(),
                icon: Icon(Icons.open_in_new, color: theme.colorScheme.onSurface, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
