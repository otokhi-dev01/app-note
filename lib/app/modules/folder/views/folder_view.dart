import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/folder_controller.dart';
import '../widgets/folder_create_modal.dart';
import '../widgets/folder_section_header.dart';
import '../widgets/folder_tile.dart';
import '../widgets/folder_all_notes_tile.dart';
import '../widgets/folder_system_tiles.dart';
import '../widgets/folder_bottom_bar.dart';

class FolderView extends GetView<FolderController> {
  const FolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true,
        extendBodyBehindAppBar: true,
        bottomNavigationBar: FolderBottomBar(controller: controller),
        body: RefreshIndicator(
          onRefresh: () => controller.fetchFolders(refresh: true),
          color: theme.primaryColor,
          backgroundColor: theme.scaffoldBackgroundColor,
          edgeOffset: 140,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [_buildAppBar(context), _buildFolderList(context)],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
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
      title: LayoutBuilder(
        builder: (context, constraints) {
          final double percentage =
              (constraints.maxHeight - kToolbarHeight) /
              (140.0 - kToolbarHeight);
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
                shape: GlassShape.circle,
                showGlow: true,
                thickness: 8,
                opacity: 0.15,
                blur: 10,
                child: IconButton(
                  onPressed: () => Get.to(
                        () => FolderCreateModal(controller: controller),
                    fullscreenDialog: true,
                    transition: Transition.cupertino,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        CupertinoIcons.folder,
                        color: AppTheme.folderPink,
                        size: 27,
                      ),
                      Positioned(
                        right: -3,
                        top: -1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppTheme.folderPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.plus,
                              color: Colors.white,
                              size: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(() => _buildEditButton(context)),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 5),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final double percentage =
                (constraints.maxHeight - kToolbarHeight) /
                (140.0 - kToolbarHeight);
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
    );
  }

  Widget _buildEditButton(BuildContext context) {
    final theme = Theme.of(context);
    if (controller.isEditing.value) {
      return LiquidGlassContainer(
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        showGlow: true,
        thickness: 8,
        opacity: 0.15, // Lower opacity for high-fidelity glass look
        blur: 10,
        child: GestureDetector(
          onTap: controller.toggleEditing,
          child: Center(
            child: Icon(
              Icons.check,
              color: theme.colorScheme.onSurface,
              size: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return LiquidGlassContainer(
      height: 44,
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      showGlow: true,
      thickness: 8,
      opacity: 0.15, // Lower opacity for high-fidelity glass look
      blur: 10,
      child: TextButton(
        onPressed: controller.toggleEditing,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  Widget _buildFolderList(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.isLoading.value) {
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            ),
          );
        }

        // Apply sorting based on user preference
        controller.sortFolders();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            if (controller.iCloudFolders.isNotEmpty) ...[
              FolderSectionHeader(
                title: "iCloud",
                isExpanded: controller.isICloudExpanded,
                onTap: controller.toggleICloud,
              ),
              Obx(
                () => controller.isICloudExpanded.value
                    ? _buildFolderGroup(context, controller.iCloudFolders)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],
            if (controller.sharedFolders.isNotEmpty) ...[
              FolderSectionHeader(
                title: "Shared",
                isExpanded: controller.isSharedExpanded,
                onTap: controller.toggleShared,
              ),
              Obx(
                () => controller.isSharedExpanded.value
                    ? _buildFolderGroup(context, controller.sharedFolders)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],
            FolderSectionHeader(
              title: "On My iPhone",
              isExpanded: controller.isOnMyiPhoneExpanded,
              onTap: controller.toggleOnMyiPhone,
            ),
            Obx(
              () => controller.isOnMyiPhoneExpanded.value
                  ? Column(
                      children: [
                        // System special: All on My iPhone
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GlassCard(
                            borderRadius: 30,
                            children: [
                              FolderAllNotesTile(controller: controller),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // User Created Folders Container
                        if (controller.onMyiPhoneFolders.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GlassCard(
                              borderRadius: 30,
                              children: [
                                for (
                                  int i = 0;
                                  i < controller.onMyiPhoneFolders.length;
                                  i++
                                ) ...[
                                  FolderTile(
                                    folder: controller.onMyiPhoneFolders[i],
                                    controller: controller,
                                  ),
                                  if (i <
                                      controller.onMyiPhoneFolders.length - 1)
                                    const Divider(indent: 56, height: 1),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        FolderSectionHeader(
                          title: "Note",
                          isExpanded: controller.isNotesSectionExpanded,
                          onTap: controller.toggleNotesSection,
                        ),

                        Obx(
                          () => controller.isNotesSectionExpanded.value
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: GlassCard(
                                    borderRadius: 30,
                                    children: [
                                      FolderSystemTiles(controller: controller),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 120),
          ],
        );
      }),
    );
  }

  Widget _buildFolderGroup(
    BuildContext context,
    List folders, {
    bool includeSystem = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderRadius: 30,
        children: [
          if (includeSystem) ...[
            FolderAllNotesTile(controller: controller),
            const Divider(indent: 56, height: 1),
          ],
          for (int i = 0; i < folders.length; i++) ...[
            FolderTile(folder: folders[i], controller: controller),
            if (i < folders.length - 1 || includeSystem)
              const Divider(indent: 56, height: 1),
          ],
          if (includeSystem) FolderSystemTiles(controller: controller),
        ],
      ),
    );
  }
}
