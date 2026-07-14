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

    return Scaffold(
      backgroundColor: style.background,
      appBar: AppBar(
        backgroundColor: style.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.orange),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _SettingsSection(
            style: style,
            title: 'ACCOUNT',
            children: [
              _SettingsRow(
                style: style,
                icon: CupertinoIcons.person_circle_fill,
                iconColor: AppColors.primary,
                title: 'User Profile',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.snackbar(
                    "User Profile", 
                    "You are logged in as a guest user.",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 16,
                  );
                },
              ),
              _SettingsRow(
                style: style,
                icon: CupertinoIcons.cloud_fill,
                iconColor: const Color(0xFF5AC8FA),
                title: 'iCloud Sync',
                trailing: const CupertinoSwitch(value: true, onChanged: null),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            style: style,
            title: 'VIEW',
            children: [
              _SettingsRow(
                style: style,
                icon: CupertinoIcons.moon_fill,
                iconColor: const Color(0xFF5856D6),
                title: 'Dark Mode',
                trailing: Obx(() => CupertinoSwitch(
                      value: controller.isDarkMode.value,
                      onChanged: (_) => controller.toggleDarkMode(),
                    )),
              ),
              _SettingsRow(
                style: style,
                icon: CupertinoIcons.textformat_size,
                iconColor: AppColors.orange,
                title: 'Font Size',
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            style: style,
            title: 'SUPPORT',
            children: [
              _SettingsRow(
                style: style,
                icon: CupertinoIcons.info_circle_fill,
                iconColor: Colors.grey,
                title: 'About Notes',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.snackbar(
                    "About Notes", 
                    "Version 1.0.0 (Build 2026)",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    margin: const EdgeInsets.all(16),
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
                    "Support is not available in the demo version.",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 16,
                  );
                },
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 40),
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
                isLast: true,
                hideChevron: true,
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from your account?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text('Sign Out'),
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

  const _SettingsSection({required this.style, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.grey),
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
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLast;
  final bool hideChevron;

  const _SettingsRow({
    required this.style,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    this.onTap,
    this.isLast = false,
    this.hideChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: title == 'User Profile' || title == 'Dark Mode' || title == 'About Notes' || title == 'Sign Out' ? const Radius.circular(10) : Radius.zero,
          bottom: isLast ? const Radius.circular(10) : Radius.zero,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(6)),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 17, color: titleColor ?? style.primaryText, fontWeight: FontWeight.w400),
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else if (!hideChevron)
                    const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
                ],
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Divider(height: 0.5, color: style.border.withValues(alpha: 0.5)),
              ),
          ],
        ),
      ),
    );
  }
}
