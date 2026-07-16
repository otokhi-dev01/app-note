import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/app/theme/app_colors.dart';
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
        body: IndexedStack(
          index: controller.selectedTab.value,
          children: [
            _NotesPage(controller: controller),
            _FoldersPage(controller: controller),
            _SearchPage(controller: controller),
            _GoalsPage(controller: controller),
          ],
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
