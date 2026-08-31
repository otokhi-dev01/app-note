import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_toggle_button.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_create_modal.dart';
import 'package:Note/features/folder/presentation/widgets/folder_section_header.dart';
import 'package:Note/features/folder/presentation/widgets/folder_tile.dart';
import 'package:Note/features/folder/presentation/widgets/folder_all_notes_tile.dart';
import 'package:Note/features/folder/presentation/widgets/folder_system_tiles.dart';
import 'package:Note/features/folder/presentation/widgets/folder_bottom_bar.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/settings/presentation/widgets/settings_drawer.dart';

class FolderView extends GetView<FolderController> {
  const FolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      child: Scaffold(
        key: settingsHostScaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        drawer: const SettingsDrawer(),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => controller.fetchFolders(refresh: true),
              color: theme.primaryColor,
              backgroundColor: theme.scaffoldBackgroundColor,
              edgeOffset: MediaQuery.paddingOf(context).top + 52,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [_buildAppBar(context), _buildFolderList(context)],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FolderBottomBar(controller: controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppScreenSliverAppBar(
      centerTitle: true,
      leading: Builder(
        builder: (drawerContext) => CustomGlassButton(
          onPressed: () => Scaffold.of(drawerContext).openDrawer(),
          width: 44,
          height: 44,
          shape: GlassShape.circle,
          blur: 10,
          opacity: 0.15,
          thickness: 8,
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.settings_solid,
            color: theme.primaryColor,
            size: 30,
          ),
        ),
      ),
      title: "folder_title".tr,
      actions: [
        // CustomGlassButton(
        //   onPressed: () => Get.to(
        //     () => FolderCreateModal(controller: controller),
        //     fullscreenDialog: true,
        //     transition: Transition.cupertino,
        //   ),
        //   width: 44,
        //   height: 44,
        //   shape: GlassShape.circle,
        //   blur: 10,
        //   opacity: 0.15,
        //   thickness: 8,
        //   padding: EdgeInsets.zero,
        //   child: Stack(
        //     clipBehavior: Clip.none,
        //     alignment: Alignment.center,
        //     children: [
        //       Icon(CupertinoIcons.folder, color: theme.primaryColor, size: 24),
        //       Positioned(
        //         right: -2,
        //         top: -1,
        //         child: Container(
        //           width: 13,
        //           height: 14,
        //           decoration: BoxDecoration(
        //             color: theme.primaryColor,
        //             shape: BoxShape.circle,
        //           ),
        //           child: const Center(
        //             child: Icon(
        //               CupertinoIcons.plus,
        //               color: Colors.white,
        //               size: 10,
        //               fontWeight: FontWeight.bold,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        _buildLanguageButton(),
        Obx(() => _buildEditButton(context)),
      ],
    );
  }

  Widget _buildLanguageButton() {
    return const LanguageToggleButton();
  }

  Widget _buildEditButton(BuildContext context) {
    final theme = Theme.of(context);
    if (controller.isEditing.value) {
      return CustomGlassButton(
        onPressed: controller.toggleEditing,
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        padding: EdgeInsets.zero,
        child: Icon(
          Icons.check,
          color: theme.primaryColor,
          size: 24,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return CustomGlassButton(
      onPressed: controller.toggleEditing,
      height: 44,
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      blur: 10,
      opacity: 0.15,
      thickness: 8,
      child: Text(
        "folder_edit".tr,
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 17),
      ),
    );
  }

  void _createFolderInSection(BuildContext context, String sectionKeyword) {
    Get.to(
      () => FolderCreateModal(
        controller: controller,
        sectionKeyword: sectionKeyword,
      ),
      fullscreenDialog: true,
      transition: Transition.cupertino,
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            FolderSectionHeader(
              title: "folder_section_icloud".tr,
              isExpanded: controller.isICloudExpanded,
              onTap: controller.toggleICloud,
              onCreateFolder: () => _createFolderInSection(context, 'iCloud'),
            ),
            Obx(
              () => controller.isICloudExpanded.value
                  ? _buildFolderGroup(context, controller.iCloudFolders)
                  : const SizedBox.shrink(),
            ),
            // const SizedBox(height: 24),
            // FolderSectionHeader(
            //   title: "Shared",
            //   isExpanded: controller.isSharedExpanded,
            //   onTap: controller.toggleShared,
            // ),
            Obx(
              () => controller.isSharedExpanded.value
                  ? _buildFolderGroup(context, controller.sharedFolders)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            FolderSectionHeader(
              title: "folder_section_on_my_phone".tr,
              isExpanded: controller.isOnMyiPhoneExpanded,
              onTap: controller.toggleOnMyiPhone,
              onCreateFolder: () => _createFolderInSection(context, ''),
            ),
            Obx(
              () => controller.isOnMyiPhoneExpanded.value
                  ? _buildFolderGroup(context, controller.onMyiPhoneFolders)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // SYSTEM "SOURCES" SECTION
            FolderSectionHeader(
              title: "folder_section_sources".tr,
              isExpanded: controller.isNotesSectionExpanded,
              onTap: controller.toggleNotesSection,
            ),
            Obx(
              () => controller.isNotesSectionExpanded.value
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassCard(
                        borderRadius: 30,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [FolderSystemTiles(controller: controller)],
                      ),
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
    List<Folder> folders, {
    bool includeSystem = false,
  }) {
    if (folders.isEmpty && !includeSystem) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderRadius: 30,
        children: [
          if (includeSystem) ...[
            FolderAllNotesTile(controller: controller),
            const Divider(indent: 56, height: 1),
          ],
          ..._buildRecursiveFolderList(folders),
          if (includeSystem) FolderSystemTiles(controller: controller),
        ],
      ),
    );
  }

  List<Widget> _buildRecursiveFolderList(
    List<Folder> folders, {
    int depth = 0,
  }) {
    List<Widget> list = [];
    for (int i = 0; i < folders.length; i++) {
      final folder = folders[i];
      list.add(
        FolderTile(folder: folder, controller: controller, depth: depth),
      );

      if (folder.subFolders.isNotEmpty &&
          controller.isFolderExpanded(folder.id)) {
        list.add(const Divider(indent: 56, height: 1, thickness: 0.5));
        list.addAll(
          _buildRecursiveFolderList(folder.subFolders, depth: depth + 1),
        );
      }

      // Add divider between items at the SAME level
      if (i < folders.length - 1) {
        list.add(const Divider(indent: 56, height: 1, thickness: 0.5));
      }
    }
    return list;
  }
}
