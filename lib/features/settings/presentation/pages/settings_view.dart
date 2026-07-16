import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/features/settings/presentation/controllers/settings_controller.dart';
import 'package:notes/features/settings/presentation/widgets/settings_components.dart';
import 'package:notes/features/settings/presentation/widgets/settings_palette.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = SettingsPalette.of(context);
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
          SettingsSection(
            style: style,
            title: 'ACCOUNT',
            children: [
              SettingsRow(
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
          SettingsSection(
            style: style,
            title: 'VIEW',
            children: [
              Obx(
                () => SettingsRow(
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
          SettingsSection(
            style: style,
            title: 'SUPPORT',
            children: [
              SettingsRow(
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
              SettingsRow(
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
          SettingsSection(
            style: style,
            title: '',
            children: [
              SettingsRow(
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
            onPressed: () async {
              Get.back<void>();
              try {
                await controller.setThemeMode(mode);
              } catch (_) {
                final appContext = Get.context;
                final errorColors = appContext == null
                    ? const ColorScheme.light()
                    : Theme.of(appContext).colorScheme;
                Get.snackbar(
                  'Appearance Not Saved',
                  'The appearance setting could not be saved. Please try again.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: errorColors.error,
                  colorText: errorColors.onError,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 16,
                );
              }
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
            onPressed: () async {
              Get.back();
              try {
                await controller.logout();
              } catch (_) {
                final appContext = Get.context;
                final errorColors = appContext == null
                    ? const ColorScheme.light()
                    : Theme.of(appContext).colorScheme;
                Get.snackbar(
                  'Sign Out Failed',
                  'Could not sign out. Please try again.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: errorColors.error,
                  colorText: errorColors.onError,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 16,
                );
              }
            },
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
