import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/presentation/widgets/app_refresh_button.dart';
import '../../../main/presentation/controller/main_navigation_controller.dart';
import '../../../notes/presentation/controllers/home_controller.dart';
import '../widgets/profile_header_card_widget.dart';
import '../widgets/profile_menu_card_widget.dart';
import '../widgets/profile_menu_divider_widget.dart';
import '../widgets/profile_menu_tile_widget.dart';
import '../widgets/profile_section_label_widget.dart';
import '../widgets/profile_statistics_section_widget.dart';

class ProfileView extends GetView<HomeController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color pageColor = theme.scaffoldBackgroundColor;

    return ColoredBox(
      color: pageColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            automaticallyImplyLeading: false,
            stretch: true,
            border: null,
            backgroundColor: pageColor.withValues(alpha: 0.94),
            largeTitle: Text(
              'Profile'.tr,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            trailing: AppRefreshButton(
              semanticsLabel: 'Refresh profile data',
              onPressed: controller.loadAll,
            ),
          ),
          CupertinoSliverRefreshControl(onRefresh: controller.loadAll),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList.list(
              children: <Widget>[
                Obx(
                  () => ProfileHeaderCardWidget(
                    displayName: controller.profileDisplayName,
                    statusText: controller.profileStatusText,
                    avatarUrl: controller.profileAvatarUrl,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => ProfileStatisticsSectionWidget(
                    folderCount: controller.folders.length,
                    noteCount: controller.activeNotes.length,
                  ),
                ),
                const SizedBox(height: 20),
                const ProfileSectionLabelWidget(title: 'Content'),
                const SizedBox(height: 8),
                ProfileMenuCardWidget(
                  children: <Widget>[
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.folder_fill,
                      title: 'My Folders',
                      subtitle: 'View and manage your folders',
                      onTap: () {
                        _changeTab(0);
                      },
                    ),
                    const ProfileMenuDividerWidget(),
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.doc_text_fill,
                      title: 'My Notes',
                      subtitle: 'View all of your notes',
                      onTap: () {
                        controller.selectAllNotes();
                        _changeTab(1);
                      },
                    ),
                    const ProfileMenuDividerWidget(),
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.trash_fill,
                      title: 'Recycle Bin',
                      subtitle: 'Restore deleted folders and archived notes',
                      onTap: () {
                        Get.toNamed(AppRoutes.recycleBin);
                      },
                    ),
                    const ProfileMenuDividerWidget(),
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.refresh,
                      title: 'Refresh Data',
                      subtitle: 'Reload folders and notes',
                      onTap: controller.loadAll,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const ProfileSectionLabelWidget(title: 'Application'),
                const SizedBox(height: 8),
                ProfileMenuCardWidget(
                  children: <Widget>[
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.info_circle_fill,
                      title: 'About Piisiit Note',
                      subtitle: 'Version and application information',
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),
                    const ProfileMenuDividerWidget(),
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.square_arrow_right,
                      title: 'Sign Out',
                      subtitle: 'Sign out from this device',
                      isDestructive: true,
                      showChevron: false,
                      onTap: () {
                        _confirmLogout(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changeTab(int index) {
    if (!Get.isRegistered<MainNavigationController>()) {
      return;
    }

    Get.find<MainNavigationController>().changeTab(index);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Sign Out?'),
          content: const Text(
            'You will need to sign in again to access your notes.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.logout();
    }
  }

  Future<void> _showAboutDialog(BuildContext context) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Piisiit Note'),
          content: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'A modern note application for organizing folders and notes.\n\n'
              'Version 1.0.0',
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}
