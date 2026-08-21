import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/features/profile/presentation/widgets/profile_more_popup.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/glass_surfaces.dart';

/// A modern, standalone user profile screen.
/// 
/// Replaces the simple identity row in Settings with a dedicated destination 
/// that treats the user's identity as a first-class feature. Designed with 
/// "Liquid Glass" aesthetics: a large hero avatar with a matching soft halo, 
/// grouped glass cards for details, and a clear, focused layout.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: Column(
                  children: [
                    _buildHero(context),
                    const SizedBox(height: 32),
                    _buildDetailsCard(context),
                    const SizedBox(height: 24),
                    _buildStatsGrid(context),
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
      expandedHeight: 0, // Compact bar for this view
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
      actions: [
        ProfileMorePopup(
          controller: controller,
          triggerBuilder: (context, toggleMenu) => CustomGlassButton(
            onPressed: toggleMenu,
            width: 44,
            height: 44,
            shape: GlassShape.circle,
            blur: 10,
            opacity: 0.15,
            thickness: 8,
            padding: EdgeInsets.zero,
            child: Icon(
              Icons.more_horiz,
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ),
      ],
      title: Text(
        "profile_title".tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
    );
  }

  /// The large avatar and name block at the top.
  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final isGuest = controller.isGuestMode.value;
      final imagePath = controller.userImagePath.value;
      final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

      return Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Soft halo glow behind avatar
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Main Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: hasImage ? FileImage(File(imagePath)) : null,
                  child: hasImage
                      ? null
                      : Icon(
                          CupertinoIcons.person_fill,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 60,
                        ),
                ),
              ),
              // Edit button badge
              if (!isGuest)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: CustomGlassButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      controller.updateProfileImage();
                    },
                    width: 38,
                    height: 38,
                    shape: GlassShape.circle,
                    blur: 15,
                    opacity: 0.9,
                    thickness: 2,
                    glassColor: theme.colorScheme.primary,
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.camera_fill,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ProfileMorePopup(
            controller: controller,
            triggerBuilder: (context, toggleMenu) => GestureDetector(
              onTap: isGuest ? null : toggleMenu,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.userName.value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isGuest) ...[
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.chevron_down_circle_fill,
                      size: 22,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (controller.userPhone.value.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              controller.userPhone.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ],
      );
    });
  }

  /// A grouped card for personal details.
  Widget _buildDetailsCard(BuildContext context) {
    final theme = Theme.of(context);
    return CustomGlassContainer(
      borderRadius: 24,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.zero,
      showGlow: true,
      child: Column(
        children: [
          ProfileMorePopup(
            controller: controller,
            triggerBuilder: (context, toggleMenu) => _buildDetailRow(
              context,
              icon: CupertinoIcons.person_circle,
              label: "full_name_label".tr,
              value: controller.userName.value,
              onTap: controller.isGuestMode.value ? null : toggleMenu,
            ),
          ),
          Divider(
            height: 1,
            indent: 52,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.phone_fill,
            label: "phone_label".tr,
            value: controller.userPhone.value.isEmpty 
                ? "not_available".tr 
                : controller.userPhone.value,
          ),
          Divider(
            height: 1,
            indent: 52,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.shield_fill,
            label: "account_status_label".tr,
            value: controller.isGuestMode.value ? "guest_status".tr : "verified_status".tr,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modern grid showing some account "stats" or activity highlights.
  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            title: "joined_label".tr,
            value: "Aug 2026",
            icon: CupertinoIcons.calendar,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            context,
            title: "tier_label".tr,
            value: "Free",
            icon: CupertinoIcons.star_fill,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return CustomGlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
