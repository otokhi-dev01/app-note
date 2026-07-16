import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/app/theme/colors.dart';
import 'settings_controller.dart';
import '../home/home_style.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: style.background,
      appBar: AppBar(
        backgroundColor: style.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: AppColors.orange),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: style.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _SettingsSection(
            style: style,
            title: 'ACCOUNT',
            children: [
              _SettingsRow(
                style: style,
                icon: CupertinoIcons.person_circle_fill,
                iconColor: AppColors.primary,
                title: controller.accountIdentifier,
                isFirst: true,
                isLast: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.snackbar(
                    'Account',
                    'Signed in as ${controller.accountIdentifier}.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: colors.surface,
                    colorText: colors.onSurface,
                    margin: EdgeInsets.all(16),
                    borderRadius: 16,
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 24),
          _SettingsSection(
            style: style,
            title: 'VIEW',
            children: [
              Obx(
                () => _SettingsRow(
                  style: style,
                  icon: CupertinoIcons.circle_lefthalf_fill,
                  iconColor: const Color(0xFF5856D6),
                  title: 'Appearance',
                  subtitle: controller.themeModeLabel,
                  onTap: () => _showAppearancePicker(context),
                  isFirst: true,
                  isLast: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _SettingsSection(
            style: style,
            title: 'SUPPORT',
            children: [
              _SettingsRow(
                style: style,
                icon: CupertinoIcons.info_circle_fill,
                iconColor: Colors.grey,
                title: 'About Notes',
                isFirst: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.snackbar(
                    "About Notes",
                    "Version 1.0.0 (Build 2026)",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: colors.surface,
                    colorText: colors.onSurface,
                    margin: EdgeInsets.all(16),
                    borderRadius: 16,
                  );
                },
              ),
              _SettingsRow(
                style: style,
                icon: CupertinoIcons.question_circle_fill,
                iconColor: AppColors.primary,
                title: 'Help & Feedback',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.snackbar(
                    "Help & Feedback",
                    'Help and feedback are not available yet.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: colors.surface,
                    colorText: colors.onSurface,
                    margin: EdgeInsets.all(16),
                    borderRadius: 16,
                  );
                },
                isLast: true,
              ),
            ],
          ),
          SizedBox(height: 40),
          _SettingsSection(
            style: style,
            title: '',
            children: [
              _SettingsRow(
                style: style,
                icon: CupertinoIcons.square_arrow_right,
                iconColor: AppColors.red,
                title: 'Sign Out',
                titleColor: AppColors.red,
                onTap: () => _showSignOutDialog(context),
                isFirst: true,
                isLast: true,
                hideChevron: true,
              ),
            ],
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showAppearancePicker(BuildContext context) {
    HapticFeedback.lightImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Appearance'),
        message: const Text(
          'System Default follows your device appearance automatically.',
        ),
        actions: ThemeMode.values.map((mode) {
          final label = switch (mode) {
            ThemeMode.system => 'System Default',
            ThemeMode.light => 'Light',
            ThemeMode.dark => 'Dark',
          };
          return CupertinoActionSheetAction(
            onPressed: () {
              controller.setThemeMode(mode);
              Get.back<void>();
            },
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (controller.themeMode.value == mode) ...[
                    const Icon(CupertinoIcons.check_mark, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back<void>(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out from your account?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final HomeStyle style;
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.style,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: style.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final HomeStyle style;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;
  final bool isLast;
  final bool hideChevron;
  final bool isFirst;

  const _SettingsRow({
    required this.style,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
    this.isLast = false,
    this.hideChevron = false,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(10) : Radius.zero,
          bottom: isLast ? const Radius.circular(10) : Radius.zero,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            color: titleColor ?? style.primaryText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: style.secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!hideChevron)
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: Colors.grey,
                    ),
                ],
              ),
            ),
            if (!isLast)
              Padding(
                padding: EdgeInsets.only(left: 54),
                child: Divider(
                  height: 0.5,
                  color: style.border.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
