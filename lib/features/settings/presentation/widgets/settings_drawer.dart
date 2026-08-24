import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/theme_storage.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_picker_sheet.dart';
import 'package:Note/core/storage/language_preferences.dart';

/// The Folders screen's slide-out settings panel, opened from the gear icon.
///
/// A flat, plain-list layout (light square icon badges, no card grouping) —
/// every row here is real, working navigation: Profile Details, Appearance,
/// Note Preferences, Dark Mode, Language, Change Password, and Help Center.
/// Actual field editing lives on [Routes.PROFILE] now, reached via the first
/// row, rather than duplicated here.
class SettingsDrawer extends GetView<ProfileController> {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      width: MediaQuery.sizeOf(context).width * 0.84,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  _buildAvatarBlock(context),
                  const SizedBox(height: 24),
                  _buildRow(
                    context,
                    icon: CupertinoIcons.person_crop_circle_fill,
                    title: "profile_title".tr,
                    highlighted: true,
                    onTap: () => _closeThenGo(context, Routes.PROFILE),
                  ),
                  _buildRow(
                    context,
                    icon: CupertinoIcons.paintbrush_fill,
                    title: "appearance_title".tr,
                    onTap: () => _closeThenGo(context, Routes.APPEARANCE),
                  ),
                  _buildRow(
                    context,
                    icon: CupertinoIcons.list_bullet,
                    title: "note_preferences_title".tr,
                    onTap: () => _closeThenGo(context, Routes.NOTE_PREFERENCES),
                  ),
                  _buildDarkModeRow(context),
                  LanguagePickerMenu(
                    morphFromZero: true,
                    triggerBuilder: (context, toggleMenu) => _buildRow(
                      context,
                      icon: CupertinoIcons.globe,
                      title: "language_title".tr,
                      trailingText: LanguagePreferences().language.label,
                      onTap: toggleMenu,
                    ),
                  ),
                  Obx(
                    () => controller.isGuestMode.value
                        ? const SizedBox.shrink()
                        : _buildRow(
                            context,
                            icon: CupertinoIcons.lock_rotation,
                            title: "reset_password_title".tr,
                            onTap: controller.requestPasswordReset,
                          ),
                  ),
                  _buildRow(
                    context,
                    icon: CupertinoIcons.question_circle_fill,
                    title: "help_center_title".tr,
                    onTap: () => _closeThenGo(context, Routes.HELP_CENTER),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  _buildAccountAction(context),
                  _buildDeleteAccountAction(context),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "settings_title".tr,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              CupertinoIcons.xmark,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  /// Identity block above the list. Tapping it opens the profile details
  /// screen; the camera button keeps its own image-picker action.
  Widget _buildAvatarBlock(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final isGuest = controller.isGuestMode.value;
      final imagePath = controller.userImagePath.value;
      final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();
      // Default app accent — not the user's own picked [ProfileController.
      // userColor], which is scoped to the Color field itself rather than
      // recoloring the rest of the screen.
      final accent = theme.colorScheme.primary;

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _closeThenGo(context, Routes.PROFILE),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: hasImage
                          ? FileImage(File(imagePath))
                          : null,
                      child: hasImage
                          ? null
                          : Icon(
                              CupertinoIcons.person_fill,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 40,
                            ),
                    ),
                    if (!isGuest)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: CustomGlassButton(
                          onPressed: controller.updateProfileImage,
                          width: 24,
                          height: 24,
                          shape: GlassShape.circle,
                          blur: 10,
                          opacity: 0.9,
                          thickness: 2,
                          glassColor: theme.scaffoldBackgroundColor,
                          padding: EdgeInsets.zero,
                          child: Icon(
                            CupertinoIcons.camera_fill,
                            size: 12,
                            color: accent,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (!isGuest &&
                          controller.userUsername.value.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@${controller.userUsername.value}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      CustomGlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        borderRadius: 20,
                        glassColor: theme.colorScheme.surfaceContainerHighest,
                        opacity: 0.12,
                        blur: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.person_crop_circle_fill,
                              size: 11,
                              color: accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isGuest
                                  ? "guest_status".tr
                                  : (controller.userAccount.value.isEmpty
                                        ? "account_label".tr
                                        : controller.userAccount.value),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
    bool highlighted = false,
  }) {
    final theme = Theme.of(context);
    final badgeColor = highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    // Solid base color — CustomGlassContainer's own `opacity` below applies
    // the translucency, so this isn't pre-faded and double-stacked with it.
    final badgeBg = highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    return Material(
      color: highlighted
          ? theme.colorScheme.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              CustomGlassContainer(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                borderRadius: 10,
                glassColor: badgeBg,
                opacity: highlighted ? 0.12 : 0.5,
                blur: 8,
                child: Icon(icon, size: 18, color: badgeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                    color: highlighted ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                CupertinoIcons.chevron_forward,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeRow(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          CustomGlassContainer(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            borderRadius: 10,
            glassColor: theme.colorScheme.surfaceContainerHighest,
            opacity: 0.5,
            blur: 8,
            child: Icon(
              CupertinoIcons.moon_fill,
              size: 18,
              color: isDark
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "dark_mode".tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: isDark,
            activeThumbColor: theme.colorScheme.primary,
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
    final theme = Theme.of(context);

    return Obx(() {
      final isGuest = guestMode.isGuestMode.value;
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                CustomGlassContainer(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  borderRadius: 10,
                  glassColor: Colors.red,
                  opacity: 0.12,
                  blur: 8,
                  child: Icon(
                    isGuest
                        ? CupertinoIcons.arrow_right_circle
                        : CupertinoIcons.square_arrow_right,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isGuest ? "log_in_create_account".tr : "log_out".tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDeleteAccountAction(BuildContext context) {
    final guestMode = Get.find<GuestModeService>();
    final theme = Theme.of(context);

    return Obx(() {
      if (guestMode.isGuestMode.value) return const SizedBox.shrink();

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _closeThenGo(context, Routes.ACCOUNT),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                CustomGlassContainer(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  borderRadius: 10,
                  glassColor: theme.colorScheme.surfaceContainerHighest,
                  opacity: 0.12,
                  blur: 8,
                  child: const Icon(
                    CupertinoIcons.trash_fill,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "delete_account_title".tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _logout() async {
    await Get.find<Logout>()(const NoParams());
    unawaited(Get.offAllNamed(Routes.ONBOARDING));
  }

  /// Closes the drawer, then pushes [route] on the next frame instead of in
  /// the same tap callback.
  ///
  /// Uses `Navigator.of(context).pop()` — tied to this exact row's own
  /// `context`, which sits below the Scaffold that owns this Drawer — rather
  /// than `Get.back()`, which resolves against GetX's own root navigator key
  /// and isn't guaranteed to be the same Navigator instance the Drawer's
  /// local-history entry (its actual close mechanism) was registered on.
  /// Pushing the new route is also deferred a frame so it lands after the
  /// drawer's close animation actually finishes, instead of racing it.
  void _closeThenGo(BuildContext context, String route) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.toNamed(route));
  }
}
