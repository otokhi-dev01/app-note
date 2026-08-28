import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/features/settings/presentation/widgets/preference_actions.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/app_logo.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_popup.dart';
import 'package:Note/shared/widgets/language_toggle_button.dart';

/// The settings panel opened from the Folders screen.
///
/// The drawer uses a restrained, grouped layout: identity first, everyday
/// preferences next, then support and account actions. All editing remains on
/// the dedicated settings screens.
class SettingsDrawer extends GetView<ProfileController> {
  const SettingsDrawer({super.key});

  static const _drawerRadius = 28.0;
  static const _iosBlue = Color(0xFF007AFF);
  static const _iosGreen = Color(0xFF34C759);
  static const _iosIndigo = Color(0xFF5856D6);
  static const _iosOrange = Color(0xFFFF9500);
  static const _iosPurple = Color(0xFFAF52DE);
  static const _iosRed = Color(0xFFFF3B30);
  static const _iosGray = Color(0xFF8E8E93);

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
                  _buildSectionLabel(context, 'section preferences'.tr),
                  _buildGroup(
                    context,
                    children: [
                      _buildRow(
                        context,
                        icon: CupertinoIcons.bell_fill,
                        iconColor: _iosRed,
                        title: 'notifications_title'.tr,
                        onTap: () =>
                            _closeThenGo(context, Routes.NOTIFICATIONS),
                      ),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.device_phone_portrait,
                        iconColor: _iosGray,
                        title: 'device_title'.tr,
                        onTap: () => _closeThenGo(context, Routes.DEVICE),
                      ),
                      LanguagePopup(
                        triggerBuilder: (context, toggleMenu) => _buildRow(
                          context,
                          icon: CupertinoIcons.globe,
                          iconColor: _iosBlue,
                          title: 'language_title'.tr,
                          trailingText: LanguagePreferences().language.label,
                          onTap: toggleMenu,
                        ),
                      ),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.share,
                        iconColor: _iosBlue,
                        title: 'share_title'.tr,
                        onTap: () =>
                            unawaited(PreferenceActions.shareApp(context)),
                      ),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.checkmark_shield_fill,
                        iconColor: _iosIndigo,
                        title: 'permissions_title'.tr,
                        onTap: () => _closeThenGo(context, Routes.PERMISSIONS),
                      ),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.briefcase_fill,
                        iconColor: _iosOrange,
                        title: 'pii_business_title'.tr,
                        onTap: () =>
                            unawaited(PreferenceActions.openBusiness()),
                      ),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.doc_text_fill,
                        iconColor: _iosPurple,
                        title: 'privacy_policy_title'.tr,
                        onTap: () =>
                            _closeThenGo(context, Routes.PRIVACY_POLICY),
                      ),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.chat_bubble_2_fill,
                        iconColor: _iosGreen,
                        title: 'contact us'.tr,
                        onTap: () => _closeThenGo(context, Routes.CONTACT_US),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildSectionLabel(context, 'section support'.tr),
                  Obx(
                    () => _buildGroup(
                      context,
                      children: [
                        if (!controller.isGuestMode.value)
                          _buildRow(
                            context,
                            icon: CupertinoIcons.lock_rotation,
                            iconColor: _iosOrange,
                            title: 'forgot password'.tr,
                            onTap: () => _closeThenGo(
                              context,
                              Routes.FORGOT_PASSWORD,
                              arguments: {
                                'initialPhone': controller.userPhone.value,
                                'onSubmit': controller.submitForgotPassword,
                              },
                            ),
                          ),
                        _buildRow(
                          context,
                          icon: CupertinoIcons.question_circle_fill,
                          iconColor: _iosBlue,
                          title: 'help center title'.tr,
                          onTap: () =>
                              _closeThenGo(context, Routes.HELP_CENTER),
                        ),
                        _buildRow(
                          context,
                          icon: CupertinoIcons.lock_shield_fill,
                          iconColor: _iosGreen,
                          title: 'privacy security title'.tr,
                          onTap: () =>
                              _closeThenGo(context, Routes.PRIVACY_SECURITY),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildSectionLabel(context, 'account label'.tr),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: _buildBrandFooter(context),
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
          Expanded(
            child: Text(
              'settings title'.tr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const LanguageToggleButton(),
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
      return CustomGlassContainer(
        borderRadius: 20,
        blur: 24,
        opacity: 0.12,
        thickness: 10,
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.14),
                  scheme.surface.withValues(alpha: 0.62),
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
                            child: CustomGlassButton(
                              onPressed: controller.updateProfileImage,
                              semanticLabel: 'profile_image_updated_message'.tr,
                              width: 24,
                              height: 24,
                              shape: GlassShape.circle,
                              blur: 8,
                              opacity: 0.2,
                              thickness: 5,
                              glassColor: scheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.camera_fill,
                                size: 12,
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
    return CustomGlassContainer(
      borderRadius: 18,
      blur: 20,
      opacity: 0.12,
      thickness: 8,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? iconColor,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final resolvedIconColor = iconColor ?? _iosBlue;

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
              _buildGlassIconBadge(icon, resolvedIconColor),
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
        title: 'delete account title'.tr,
        isDestructive: true,
        showChevron: true,
        onTap: () => _closeThenGo(context, Routes.DELETE_ACCOUNT),
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
    final color = isDestructive ? _iosRed : _iosBlue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _buildGlassIconBadge(icon, color),
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
          'Pii Note',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassIconBadge(IconData icon, Color color) {
    return CustomGlassContainer(
      width: 36,
      height: 36,
      borderRadius: 10,
      blur: 12,
      opacity: 0.3,
      thickness: 8,
      refractiveIndex: 1.1,
      glassColor: color.withValues(alpha: 0.82),
      glowIntensity: 0.18,
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  Future<void> _logout() async {
    await Get.find<Logout>()(const NoParams());
    unawaited(Get.offAllNamed(Routes.ONBOARDING));
  }

  Future<void> _closeThenGo(
    BuildContext context,
    String route, {
    Object? arguments,
  }) async {
    Navigator.of(context).pop();
    // Avoid overlapping disposal of the drawer's glass render layers with
    // creation of the next screen's layers on physical devices.
    await Future<void>.delayed(kThemeAnimationDuration);
    if (Get.key.currentState == null) return;
    await Get.toNamed(route, arguments: arguments);
  }
}
