import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/folder_controller.dart';

class FolderBottomBar extends StatelessWidget {
  final FolderController controller;

  const FolderBottomBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: CustomGlassTabBar.bottom(
        tabs: const [
          CustomGlassTab(
            icon: Icon(CupertinoIcons.folder),
            activeIcon: Icon(CupertinoIcons.folder_fill),
            label: 'Folders',
            semanticLabel: 'Folders',
          ),
          CustomGlassTab(
            icon: Icon(CupertinoIcons.profile_circled),
            activeIcon: Icon(CupertinoIcons.profile_circled),
            label: 'Profile',
            semanticLabel: 'Profile',
          ),
          CustomGlassTab(
            icon: Icon(CupertinoIcons.search),
            label: 'Search',
            semanticLabel: 'Search notes and folders',
          ),
        ],
        selectedIndex: 0,
        onTabSelected: (index) {
          if (index == 1) {
            Get.toNamed(Routes.PROFILE);
          } else if (index == 2) {
            Get.toNamed(Routes.SEARCH);
          }
        },
        extraButton: CustomGlassTabBarExtraButton(
          icon: const Icon(CupertinoIcons.square_pencil),
          onTap: controller.createNewNote,
          label: 'Create note',
          iconColor: theme.primaryColor,
          size: 65,
        ),
        horizontalPadding: 12,
        verticalPadding: 8,
        barHeight: 64,
        selectedIconColor: theme.primaryColor,
        unselectedIconColor: theme.colorScheme.onSurfaceVariant,
        adaptiveBrightness: true,
      ),
    );
  }
}
