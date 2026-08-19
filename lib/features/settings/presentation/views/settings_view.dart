import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/core/storage/theme_storage.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_picker_sheet.dart';

/// The front door for app-wide settings, reached from the gear button on the
/// Folders screen. Flat card layout (rather than the rest of the app's
/// liquid glass) — every row here is either real, working functionality or
/// nothing at all: no fake subscription, storage quota, password change, or
/// two-factor auth, since none of that exists in this app.
///
/// Profile editing (avatar/name) used to be its own screen reached via a
/// "Personal Information" row; it's folded directly into the identity block
/// here instead, so [ProfileController] is bound to this route too.
class SettingsView extends GetView<ProfileController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIdentity(context),
                    const SizedBox(height: 28),
                    _buildSectionLabel(context, "section_preferences".tr),
                    const SizedBox(height: 10),
                    _buildCard(context, [
                      _buildDarkModeRow(context),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.paintbrush_fill,
                        title: "appearance_title".tr,
                        onTap: () => Get.toNamed(Routes.APPEARANCE),
                      ),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.list_bullet,
                        title: "note_preferences_title".tr,
                        onTap: () => Get.toNamed(Routes.NOTE_PREFERENCES),
                      ),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.globe,
                        title: "language_title".tr,
                        trailingText: LanguagePreferences().language.label,
                        onTap: () => showLanguagePickerSheet(context),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    _buildSectionLabel(context, "section_support".tr),
                    const SizedBox(height: 10),
                    _buildCard(context, [
                      _buildRow(
                        context,
                        icon: CupertinoIcons.question_circle_fill,
                        title: "help_center_title".tr,
                        onTap: () => Get.toNamed(Routes.HELP_CENTER),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    _buildAccountAction(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return CustomGlassSliverAppBar(
      expandedHeight: 140,
      toolbarHeight: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      centerTitle: true,
      leading: CustomGlassButton(
        onPressed: () => Get.back(),
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        padding: EdgeInsets.zero,
        child: Icon(
          CupertinoIcons.chevron_left,
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
      ),
      title: Text(
        "settings_title".tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 5),
      largeTitle: Text(
        "settings_title".tr,
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 34,
        ),
      ),
    );
  }

  /// The avatar and name are editable right here — tap the camera badge to
  /// change the photo, tap the name to rename — rather than linking out to a
  /// separate Profile screen.
  Widget _buildIdentity(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final isGuest = controller.isGuestMode.value;
      final imagePath = controller.userImagePath.value;
      final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: hasImage ? FileImage(File(imagePath)) : null,
                  child: hasImage
                      ? null
                      : Icon(
                          CupertinoIcons.person_fill,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 44,
                        ),
                ),
                if (!isGuest)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: theme.colorScheme.primary,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        onTap: controller.updateProfileImage,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            CupertinoIcons.camera_fill,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: isGuest ? null : controller.updateUserName,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.userName.value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isGuest) ...[
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.pencil,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (controller.userPhone.value.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                controller.userPhone.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> rows) {
    final theme = Theme.of(context);
    return CustomGlassContainer(
      borderRadius: 18,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.zero,
      showGlow: true,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
          ],
        ],
      ),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// A real, working quick toggle: on switches to explicit dark mode, off to
  /// explicit light mode. The full System/Light/Dark picker (which this
  /// can't represent as a single switch) is still available via the
  /// "Appearance" row below it.
  Widget _buildDarkModeRow(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.moon_fill,
            color: theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text("dark_mode".tr, style: theme.textTheme.bodyLarge),
          ),
          Switch.adaptive(
            value: isDark,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (value) => ThemeStorage().switchTheme(
              value ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountAction(BuildContext context) {
    final guestMode = Get.find<GuestModeService>();

    return Obx(() {
      final isGuest = guestMode.isGuestMode.value;
      return CustomGlassButton(
        onPressed: isGuest ? _goToLogin : () => _logout(),
        semanticLabel: isGuest ? "log_in_create_account".tr : "log_out".tr,
        width: double.infinity,
        borderRadius: 18,
        foregroundColor: isGuest ? AppTheme.folderPink : Colors.red,
        glassColor: (isGuest ? AppTheme.folderPink : Colors.red).withValues(
          alpha: 0.12,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isGuest
                  ? CupertinoIcons.arrow_right_circle
                  : CupertinoIcons.square_arrow_right,
              color: isGuest ? AppTheme.folderPink : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              isGuest ? "log_in_create_account".tr : "log_out".tr,
              style: TextStyle(
                color: isGuest ? AppTheme.folderPink : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    });
  }

  void _goToLogin() => Get.offAllNamed(Routes.LOGIN);

  Future<void> _logout() async {
    await Get.find<Logout>()(const NoParams());
    Get.offAllNamed(Routes.ONBOARDING);
  }
}
