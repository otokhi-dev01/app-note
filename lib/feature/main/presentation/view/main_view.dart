import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../folders/presentation/view/folder_list_view.dart';
import '../../../notes/presentation/controllers/home_controller.dart';
import '../../../notes/presentation/view/note_list_view.dart';

import '../../../profile/presentation/views/profile_view.dart';
import '../../../search/presentation/view/search_view.dart';

import '../../../settings/view/settings_view.dart';
import '../controller/main_navigation_controller.dart';

import '../widgets/liquid_bottom_navigation_widget.dart';

class MainView extends GetView<MainNavigationController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    const List<Widget> screens = <Widget>[
      NoteListView(),
      FolderListView(),
      SearchView(),
      ProfileView(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        children: screens,
      ),
      bottomNavigationBar: Obx(() {
        /*
           * Read the observable directly inside Obx.
           * This fixes the GetX improper-use exception.
           */
        final int selectedIndex = controller.selectedIndex.value;

        return AnimatedBuilder(
          animation: controller.pageController,
          builder: (BuildContext context, Widget? child) {
            return LiquidBottomNavigation(
              page: controller.currentPage,
              selectedIndex: selectedIndex,
              onChanged: (int index) {
                controller.changeTab(index);
              },
              onCreateNote: () async {
                final dynamic result = await Get.toNamed(AppRoutes.createNote);

                if (result != true) {
                  return;
                }

                if (Get.isRegistered<HomeController>()) {
                  final HomeController homeController =
                      Get.find<HomeController>();

                  await homeController.loadAll();
                }

                await controller.changeTab(1);
              },
            );
          },
        );
      }),
    );
  }
}
