import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/core/storage/theme_storage.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/app_logo.dart';
import 'package:Note/shared/widgets/language_picker_sheet.dart';

/// The settings panel opened from the Folders screen.
///
/// The drawer uses a restrained, grouped layout: identity first, everyday
/// preferences next, then support and account actions. All editing remains on
/// the dedicated settings screens.
class SettingsDrawer extends GetView<ProfileController> {
  const SettingsDrawer({super.key});

  static const _drawerRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drawerWidth = math.min(
      MediaQuery.sizeOf(context).width * 0.88,
      400.0,
    );

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: theme.scaffoldBackgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(_drawerRadius),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildProfileCard(context),
                  const SizedBox(height: 24),
                  _buildSectionLabel(context, 'section_preferences'.tr),
                  _buildGroup(
                    context,
                    children: [
                      _buildRow(
                        context,
                        icon: CupertinoIcons.paintbrush_fill,
                        title: 'appearance_title'.tr,
                        onTap: () => _closeThenGo(context, Routes.APPEARANCE),
                      ),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.textformat_alt,
                        title: 'note_preferences_title'.tr,
                        onTap: () =>
                            _closeThenGo(context, Routes.NOTE_PREFERENCES),
                      ),
                      _buildDarkModeRow(context),
                      LanguagePickerMenu(
                        morphFromZero: true,
                        triggerBuilder: (context, toggleMenu) => _buildRow(
                          context,
                          icon: CupertinoIcons.globe,
                          title: 'language_title'.tr,
                          trailingText: LanguagePreferences().language.label,
                          onTap: toggleMenu,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildSectionLabel(context, 'section_support'.tr),
                  Obx(
                    () => _buildGroup(
                      context,
                      children: [
                        if (!controller.isGuestMode.value)
                          _buildRow(
                            context,
                            icon: CupertinoIcons.lock_rotation,
                            title: 'reset_password_title'.tr,
                            onTap: controller.requestPasswordReset,
                          ),
                        _buildRow(
                          context,
                          icon: CupertinoIcons.question_circle_fill,
                          title: 'help_center_title'.tr,
                          onTap: () =>
                              _closeThenGo(context, Routes.HELP_CENTER),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildSectionLabel(context, 'account_label'.tr),
                  Obx(
                    () => _buildGroup(
                      context,
                      children: [
                        _buildAccountAction(context),
                        if (!controller.isGuestMode.value)
                          _buildDeleteAccountAction(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBrandFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
      child: Row(
        children: [
          const AppLogo(height: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'settings_title'.tr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(CupertinoIcons.xmark, size: 17),
            color: theme.colorScheme.onSurfaceVariant,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(40),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Obx(() {
      final isGuest = controller.isGuestMode.value;
      final imagePath = controller.userImagePath.value;
      final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();
      final username = controller.userUsername.value;
      final account = controller.userAccount.value;

      return Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.14),
                scheme.surface.withValues(alpha: 0.88),
              ],
            ),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _closeThenGo(context, Routes.PROFILE),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 29,
                          backgroundColor: scheme.surfaceContainerHighest,
                          backgroundImage: hasImage
                              ? FileImage(File(imagePath))
                              : null,
                          child: hasImage
                              ? null
                              : Icon(
                                  CupertinoIcons.person_fill,
                                  color: scheme.onSurfaceVariant,
                                  size: 29,
                                ),
                        ),
                      ),
                      if (!isGuest)
                        Positioned(
                          right: -3,
                          bottom: -2,
                          child: Material(
                            color: scheme.primary,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: controller.updateProfileImage,
                              child: const SizedBox.square(
                                dimension: 24,
                                child: Icon(
                                  CupertinoIcons.camera_fill,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.userName.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!isGuest && username.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@$username',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isGuest
                                    ? 'guest_status'.tr
                                    : (account.isEmpty
                                          ? 'account_label'.tr
                                          : account),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 14,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroup(BuildContext context, {required List<Widget> children}) {
    final theme = Theme.of(context);
    final groupedChildren = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        groupedChildren.add(
          Divider(
            height: 1,
            indent: 58,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        );
      }
      groupedChildren.add(children[index]);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.38),
        ),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(children: groupedChildren),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    trailingText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 14,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.48),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? CupertinoIcons.moon_fill : CupertinoIcons.moon,
              size: 18,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'dark_mode'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: isDark,
            activeThumbColor: scheme.primary,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ThemeStorage().switchTheme(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountAction(BuildContext context) {
    final guestMode = Get.find<GuestModeService>();

    return Obx(() {
      final isGuest = guestMode.isGuestMode.value;
      return _buildActionRow(
        context,
        icon: isGuest
            ? CupertinoIcons.person_badge_plus
            : CupertinoIcons.square_arrow_right,
        title: isGuest ? 'log_in_create_account'.tr : 'log_out'.tr,
        isDestructive: !isGuest,
        showChevron: isGuest,
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isGuest) {
              Get.offAllNamed(Routes.LOGIN);
            } else {
              unawaited(_logout());
            }
          });
        },
      );
    });
  }

  Widget _buildDeleteAccountAction(BuildContext context) {
    final guestMode = Get.find<GuestModeService>();

    return Obx(() {
      if (guestMode.isGuestMode.value) return const SizedBox.shrink();

      return _buildActionRow(
        context,
        icon: CupertinoIcons.trash_fill,
        title: 'delete_account_title'.tr,
        isDestructive: true,
        showChevron: true,
        onTap: () => _closeThenGo(context, Routes.ACCOUNT),
      );
    });
  }

  Widget _buildActionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showChevron = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isDestructive ? scheme.error : scheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showChevron)
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: color.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppLogo(
          height: 17,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 7),
        Text(
          'Piisiit Note',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    await Get.find<Logout>()(const NoParams());
    unawaited(Get.offAllNamed(Routes.ONBOARDING));
  }

  void _closeThenGo(BuildContext context, String route) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.toNamed(route));
  }
}
