import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/core/presentation/brand/app_brand.dart';
import 'package:notes/core/presentation/images/image_helper.dart';
import 'package:notes/features/notes/domain/entities/folder.dart';
import 'package:notes/features/notes/domain/entities/note.dart';
import 'home_controller.dart';

part 'actions/home_actions.dart';
part 'actions/home_helpers.dart';
part 'pages/folders_page.dart';
part 'pages/goals_page.dart';
part 'pages/notes_page.dart';
part 'pages/search_page.dart';
part 'pages/trash_page.dart';
part 'widgets/folder_search_widgets.dart';
part 'widgets/goals_trash_widgets.dart';
part 'widgets/note_widgets.dart';
part 'widgets/shell_widgets.dart';
part 'widgets/state_section_widgets.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isTrashView.value) {
        return _DeletedPage(controller: controller);
      }

      return Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: AppBrandBackdrop(
          child: Column(
            children: [
              _HomeHeader(controller: controller),
              Expanded(
                child: IndexedStack(
                  index: controller.selectedTab.value,
                  children: [
                    _NotesPage(controller: controller),
                    _FoldersPage(controller: controller),
                    _SearchPage(controller: controller),
                    _GoalsPage(controller: controller),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: controller.selectedTab.value <= 1
            ? FloatingActionButton(
                key: const ValueKey('compose_note_button'),
                onPressed: controller.openCreateNote,
                tooltip: 'New note',
                child: const Icon(CupertinoIcons.square_pencil),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _LinenNavigationBar(
          selectedIndex: controller.selectedTab.value,
          onSelect: controller.selectTab,
        ),
      );
    });
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tab = controller.selectedTab.value;
    final title = switch (tab) {
      0 => controller.selectedFolder.value?.name ?? 'Notes',
      1 => 'Folders',
      2 => 'Search',
      _ => 'Writing Goals',
    };

    final actions = switch (tab) {
      0 => <Widget>[
        IconButton(
          onPressed: controller.toggleViewMode,
          tooltip: controller.isGalleryView.value
              ? 'List view'
              : 'Gallery view',
          icon: Icon(
            controller.isGalleryView.value
                ? CupertinoIcons.list_bullet
                : CupertinoIcons.square_grid_2x2,
            color: scheme.primary,
          ),
        ),
        IconButton(
          onPressed: controller.goToSettings,
          tooltip: 'More',
          icon: Icon(CupertinoIcons.ellipsis, color: scheme.primary),
        ),
      ],
      1 => <Widget>[
        IconButton(
          onPressed: controller.isFolderSyncing.value
              ? null
              : controller.syncFolders,
          tooltip: 'Sync folders',
          icon: controller.isFolderSyncing.value
              ? const SizedBox.square(
                  dimension: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(CupertinoIcons.cloud_download, color: scheme.primary),
        ),
        TextButton(
          onPressed: controller.toggleEdit,
          child: Text(controller.isEditing.value ? 'Done' : 'Edit'),
        ),
        IconButton(
          onPressed: controller.goToSettings,
          tooltip: 'More',
          icon: Icon(CupertinoIcons.ellipsis, color: scheme.primary),
        ),
      ],
      2 => <Widget>[
        TextButton(
          onPressed: controller.clearRecentSearches,
          child: const Text('Clear'),
        ),
        IconButton(
          onPressed: controller.goToSettings,
          tooltip: 'More',
          icon: Icon(CupertinoIcons.ellipsis, color: scheme.primary),
        ),
      ],
      _ => <Widget>[
        IconButton(
          onPressed: () => Get.toNamed(AppRoutes.calendar),
          tooltip: 'Calendar',
          icon: Icon(CupertinoIcons.calendar, color: scheme.primary),
        ),
        IconButton(
          onPressed: controller.goToSettings,
          tooltip: 'More',
          icon: Icon(CupertinoIcons.ellipsis, color: scheme.primary),
        ),
      ],
    };

    return _LinenHeader(
      title: title,
      onMenu: () => _showAppMenu(context, controller),
      actions: actions,
    );
  }
}
