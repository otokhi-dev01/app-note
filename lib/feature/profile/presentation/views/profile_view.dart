import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../main/presentation/controller/main_navigation_controller.dart';
import '../../../notes/presentation/controllers/home_controller.dart';
import '../widgets/profile_header_card_widget.dart';
import '../widgets/profile_menu_card_widget.dart';
import '../widgets/profile_menu_divider_widget.dart';
import '../widgets/profile_menu_tile_widget.dart';

class ProfileView extends GetView<HomeController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
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
              'Settings',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
          ),
          CupertinoSliverRefreshControl(onRefresh: controller.loadAll),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            sliver: SliverList.list(
              children: <Widget>[
                Obx(
                  () => ProfileHeaderCardWidget(
                    displayName: controller.profileDisplayName,
                    statusText: controller.profileStatusText,
                    avatarUrl: controller.profileAvatarUrl,
                  ),
                ),
                const SizedBox(height: 16),
                ProfileMenuCardWidget(
                  children: <Widget>[
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.sun_max,
                      title: 'Appearance',
                      value: 'Light',
                      onTap: () {},
                    ),
                    const ProfileMenuDividerWidget(),
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.drop,
                      title: 'Theme Color',
                      value: 'Blue',
                      onTap: () {},
                    ),
                    const ProfileMenuDividerWidget(),
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.textformat,
                      title: 'Font Size',
                      value: 'Medium',
                      onTap: () {},
                    ),
                    const ProfileMenuDividerWidget(),
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.lock,
                      title: 'Security',
                      value: 'Locked',
                      onTap: () {},
                    ),
                    const ProfileMenuDividerWidget(),
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.bell,
                      title: 'Reminders',
                      onTap: () {},
                    ),
                    const ProfileMenuDividerWidget(),
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.tray_arrow_up,
                      title: 'Backup & Export',
                      onTap: () {},
                    ),
                    const ProfileMenuDividerWidget(),
                    ProfileMenuTileWidget(
                      icon: CupertinoIcons.info,
                      title: 'About',
                      value: 'v1.0.0',
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _confirmLogout(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Center(
                          child: Text(
                            'Log Out',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Log Out?'),
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
              child: const Text('Log Out'),
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
