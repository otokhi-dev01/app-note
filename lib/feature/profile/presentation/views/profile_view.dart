import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/main/presentation/widgets/app_liquid_background_widget.dart';
import 'package:note_app/feature/main/presentation/widgets/main_tab_header_widget.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../main/presentation/controller/main_navigation_controller.dart';
import '../../../notes/presentation/controllers/home_controller.dart';

class ProfileView
    extends GetView<HomeController> {
  const ProfileView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: AppLiquidBackgroundWidget(),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  0,
                ),
                child: MainTabHeaderWidget(
                  title: 'Profile'.tr,
                  subtitle:
                  'Account and application settings',
                  onRefresh: controller.loadAll,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    120,
                  ),
                  children: <Widget>[
                    const _ProfileHeaderCard(),
                    const SizedBox(height: 14),
                    Obx(
                          () => _StatisticsCard(
                        folderCount:
                        controller.folders.length,
                        noteCount:
                        controller.notes.length,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ProfileMenuCard(
                      children: <Widget>[
                        _ProfileMenuTile(
                          icon:
                          Icons.folder_outlined,
                          title: 'My Folders',
                          subtitle:
                          'View and manage folders',
                          onTap: () {
                            Get.find<
                                MainNavigationController>()
                                .changeTab(0);
                          },
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon:
                          Icons.notes_outlined,
                          title: 'My Notes',
                          subtitle:
                          'View all your notes',
                          onTap: () {
                            controller
                                .selectAllNotes();

                            Get.find<
                                MainNavigationController>()
                                .changeTab(1);
                          },
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon:
                          Icons.refresh_rounded,
                          title: 'Refresh Data',
                          subtitle:
                          'Reload folders and notes',
                          onTap: controller.loadAll,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ProfileMenuCard(
                      children: <Widget>[
                        _ProfileMenuTile(
                          icon:
                          Icons.info_outline_rounded,
                          title: 'About Piisiit Note',
                          subtitle:
                          'Version and application information',
                          onTap: () {
                            _showAboutDialog(context);
                          },
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon:
                          Icons.logout_rounded,
                          title: 'Sign Out',
                          subtitle:
                          'Sign out from this device',
                          isDestructive: true,
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
        ),
      ],
    );
  }

  Future<void> _confirmLogout(
      BuildContext context,
      ) async {
    final bool? confirmed =
    await showCupertinoDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return CupertinoAlertDialog(
          title: const Text('Sign Out?'),
          content: const Text(
            'You will need to sign in again '
                'to access your notes.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('Cancel'),
            ),
            _ProfileMenuTile(
              icon: Icons.delete_outline_rounded,
              title: 'Recycle Bin',
              subtitle:
              'Restore deleted folders and archived notes',
              onTap: () {
                Get.toNamed(
                  AppRoutes.recycleBin,
                );
              },
            ),
            const Divider(height: 1),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
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

  Future<void> _showAboutDialog(
      BuildContext context,
      ) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return CupertinoAlertDialog(
          title: const Text('Piisiit Note'),
          content: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'A modern note application for '
                  'organizing folders and notes.\n\n'
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

class _ProfileHeaderCard
    extends StatelessWidget {
  const _ProfileHeaderCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(
            alpha: isDark ? 0.20 : 0.36,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.15 : 0.05,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color:
                  colorScheme.primary.withValues(
                    alpha: 0.28,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              size: 40,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Piisiit Note User',
            style:
            theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Signed in',
            style:
            theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final int folderCount;
  final int noteCount;

  const _StatisticsCard({
    required this.folderCount,
    required this.noteCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatisticItem(
            icon: Icons.folder_rounded,
            label: 'Folders',
            value: folderCount.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatisticItem(
            icon: Icons.notes_rounded,
            label: 'Notes',
            value: noteCount.toString(),
          ),
        ),
      ],
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatisticItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(
            alpha: isDark ? 0.20 : 0.36,
          ),
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 28,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style:
            theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style:
            theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileMenuCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius:
        BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(
            alpha: isDark ? 0.20 : 0.36,
          ),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ProfileMenuTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final Color iconColor = isDestructive
        ? colorScheme.error
        : colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                  iconColor.withValues(alpha: 0.11),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme
                          .textTheme.titleSmall
                          ?.copyWith(
                        color: isDestructive
                            ? colorScheme.error
                            : colorScheme.onSurface,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme
                          .textTheme.bodySmall
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color:
                colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}