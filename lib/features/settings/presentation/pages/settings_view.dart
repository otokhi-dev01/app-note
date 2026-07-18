import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/core/presentation/brand/app_brand.dart';
import 'package:notes/core/presentation/widgets/liquid_glass_sliver_app_bar.dart';
import 'package:notes/features/settings/presentation/controllers/settings_controller.dart';
import 'package:notes/features/settings/presentation/widgets/settings_components.dart';
import 'package:notes/features/settings/presentation/widgets/settings_palette.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = SettingsPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppBrandBackdrop(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 0),
            sliver: LiquidGlassSliverAppBar(
              height: 60,
              blur: 22,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              title: const Text('Settings'),
              leading: (context) => IconButton(
                tooltip: 'Back',
                onPressed: Get.back,
                icon: Icon(
                  CupertinoIcons.chevron_left,
                  color: style.accent,
                  size: 20,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 32 + bottomInset),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsSection(
                        style: style,
                        title: 'Account',
                        children: [
                          SettingsAccountCard(
                            style: style,
                            identifier: controller.accountIdentifier,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showInfoMessage(
                                context,
                                title: 'Notes Account',
                                message:
                                    'Signed in as ${controller.accountIdentifier}.',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      SettingsSection(
                        style: style,
                        title: 'App Preferences',
                        footer:
                            'System Default follows the appearance selected on your device.',
                        children: [
                          Obx(
                            () => SettingsRow(
                              style: style,
                              icon: CupertinoIcons.circle_lefthalf_fill,
                              iconColor: colors.tertiary,
                              title: 'Appearance',
                              subtitle: controller.themeModeLabel,
                              onTap: () => _showAppearancePicker(context),
                              isFirst: true,
                              isLast: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      SettingsSection(
                        style: style,
                        title: 'Support',
                        children: [
                          SettingsRow(
                            style: style,
                            icon: CupertinoIcons.info_circle_fill,
                            iconColor: colors.secondary,
                            title: 'About Notes',
                            isFirst: true,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showInfoMessage(
                                context,
                                title: 'About Notes',
                                message: 'Version 1.0.0 (Build 2026)',
                              );
                            },
                          ),
                          SettingsRow(
                            style: style,
                            icon: CupertinoIcons.question_circle_fill,
                            iconColor: style.accent,
                            title: 'Help & Feedback',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showInfoMessage(
                                context,
                                title: 'Help & Feedback',
                                message:
                                    'Help and feedback are not available yet.',
                              );
                            },
                            isLast: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SettingsSection(
                        style: style,
                        title: '',
                        children: [
                          SettingsRow(
                            style: style,
                            icon: CupertinoIcons.square_arrow_right,
                            iconColor: style.destructive,
                            title: 'Sign Out',
                            titleColor: style.destructive,
                            onTap: () => _showSignOutDialog(context),
                            isFirst: true,
                            isLast: true,
                            hideChevron: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoMessage(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final colors = Theme.of(context).colorScheme;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: colors.surfaceContainerHighest,
      colorText: colors.onSurface,
      margin: EdgeInsets.all(16),
      borderRadius: 18,
      borderColor: colors.outlineVariant,
      borderWidth: .5,
      duration: Duration(seconds: 3),
    );
  }

  void _showAppearancePicker(BuildContext context) {
    HapticFeedback.selectionClick();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Appearance'),
        message: const Text(
          'Choose how Notes looks. System Default updates automatically.',
        ),
        actions: ThemeMode.values.map((mode) {
          final label = switch (mode) {
            ThemeMode.system => 'System Default',
            ThemeMode.light => 'Light',
            ThemeMode.dark => 'Dark',
          };
          return Obx(() {
            final isSelected = controller.themeMode.value == mode;
            return CupertinoActionSheetAction(
              isDefaultAction: isSelected,
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                HapticFeedback.selectionClick();
                try {
                  await controller.setThemeMode(mode);
                } catch (_) {
                  _showErrorMessage(
                    title: 'Appearance Not Saved',
                    message:
                        'The appearance setting could not be saved. Please try again.',
                  );
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(label),
                  if (isSelected)
                    const Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Icon(CupertinoIcons.check_mark, size: 18),
                    ),
                ],
              ),
            );
          });
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'You will need to sign in again to access your notes on this account.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await controller.logout();
              } catch (_) {
                _showErrorMessage(
                  title: 'Sign Out Failed',
                  message: 'Could not sign out. Please try again.',
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage({required String title, required String message}) {
    final appContext = Get.context;
    final colors = appContext == null
        ? const ColorScheme.light()
        : Theme.of(appContext).colorScheme;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: colors.error,
      colorText: colors.onError,
      margin: const EdgeInsets.all(16),
      borderRadius: 18,
    );
  }
}
