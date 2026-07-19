import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/main/presentation/widgets/liquid_bottom_navigation_widget.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../folders/presentation/view/folder_list_view.dart';
import '../../../notes/presentation/controllers/home_controller.dart';
import '../../../notes/presentation/view/note_list_view.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../../../settings/view/settings_view.dart';
import '../controller/main_navigation_controller.dart';

class MainView
    extends GetView<MainNavigationController> {
  const MainView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const List<Widget> screens = <Widget>[
      FolderListView(),
      NoteListView(),
      SettingsView(),
      ProfileView(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      body: Obx(
            () => IndexedStack(
          index: controller.selectedIndex.value,
          children: screens,
        ),
      ),
      bottomNavigationBar: Obx(
            () => LiquidBottomNavigation(
          selectedIndex:
          controller.selectedIndex.value,
          onChanged: controller.changeTab,
          onCreateNote: () async {
            final dynamic result =
            await Get.toNamed(
              AppRoutes.createNote,
            );

            if (result == true &&
                Get.isRegistered<HomeController>()) {
              await Get.find<HomeController>()
                  .loadAll();
            }
          },
        ),
      ),
    );
  }
}