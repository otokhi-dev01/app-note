import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/features/profile/presentation/widgets/profile_more_popup.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// The standalone "Profile Details" screen: a compact identity header
/// (avatar, name, subtitle) followed by grouped field cards. The selected
/// [ProfileController.userColor] is scoped to the centered identity card;
/// the rest of the screen continues to use the app theme color.
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIdentityHeader(context),
                    const SizedBox(height: 32),
                    _buildSectionLabel(context, "profile_basic_info".tr),
                    const SizedBox(height: 10),
                    _buildDetailsCard(context),
                    const SizedBox(height: 28),
                    _buildStatsGrid(context),
                    const SizedBox(height: 28),
                    _buildSectionLabel(context, "account_label".tr),
                    const SizedBox(height: 10),
                    _buildActionsCard(context),
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
      expandedHeight: 0,
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
        foregroundColor: theme.colorScheme.primary,
        child: const Icon(CupertinoIcons.chevron_left, size: 24),
      ),
      actions: [
        Obx(() {
          // Read the observable while this Obx builder is executing. Reading
          // it only inside triggerBuilder happens later, outside GetX's
          // reactive scope, and causes the "improper use of GetX" exception.
          final isGuest = controller.isGuestMode.value;

          return ProfileMorePopup(
            controller: controller,
            triggerBuilder: (context, toggleMenu) => CustomGlassButton(
              onPressed: isGuest ? null : toggleMenu,
              width: 44,
              height: 44,
              borderRadius: 14,
              blur: 15,
              opacity: 0.9,
              thickness: 2,
              glassColor: theme.colorScheme.primary,
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.pencil,
                color: Colors.white,
                size: 20,
              ),
            ),
          );
        }),
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

  /// A centered glass identity card containing the avatar, username and
  /// account. The profile accent drives every icon and decorative edge.
  Widget _buildIdentityHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final isGuest = controller.isGuestMode.value;
      final imagePath = controller.userImagePath.value;
      final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();
      final accent = controller.userColor;
      final username = controller.userUsername.value;
      final account = isGuest
          ? "guest_status".tr
          : (controller.userAccount.value.isEmpty
                ? "not_set".tr
                : controller.userAccount.value);

      return CustomGlassContainer(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        borderRadius: 26,
        blur: 30,
        opacity: 0.1,
        thickness: 10,
        showGlow: true,
        glassColor: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.85),
                        accent.withValues(alpha: 0.18),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.22),
                        blurRadius: 26,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: hasImage
                        ? FileImage(File(imagePath))
                        : null,
                    child: hasImage
                        ? null
                        : Icon(
                            CupertinoIcons.person_fill,
                            color: accent,
                            size: 42,
                          ),
                  ),
                ),
                if (!isGuest)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: CustomGlassButton(
                      onPressed: controller.updateProfileImage,
                      width: 32,
                      height: 32,
                      shape: GlassShape.circle,
                      blur: 15,
                      opacity: 0.9,
                      thickness: 2,
                      glassColor: accent,
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.camera_fill,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              controller.userName.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isGuest && username.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '@$username',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: CustomGlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                borderRadius: 22,
                glassColor: accent,
                opacity: 0.12,
                blur: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.person_crop_circle_fill,
                      size: 15,
                      color: accent,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        account,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        fontSize: 12,
      ),
    );
  }

  /// "Basic Information" — Name/User/Account/Email/Phone are real, backend-
  /// backed or locally-persisted fields (Username/Account/Email/Job & Bio
  /// have no backend column yet, see [ProfileExtrasStorage], so they're
  /// edited and saved on-device rather than faked as synced data).
  Widget _buildDetailsCard(BuildContext context) {
    return Obx(() {
      final isGuest = controller.isGuestMode.value;
      final colorHex =
          controller.userColorHex.value ?? FolderAppearance.defaultColorValue;

      return Column(
        children: [
          _buildDetailRow(
            context,
            icon: CupertinoIcons.person_fill,
            label: "full_name_label".tr,
            value: controller.userName.value,
            onTap: isGuest ? null : controller.updateUserName,
          ),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.at,
            label: "username_label".tr,
            value: controller.userUsername.value.isEmpty
                ? "not_set".tr
                : '@${controller.userUsername.value}',
            onTap: isGuest ? null : controller.updateUsername,
          ),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.person_crop_circle_fill,
            label: "account_label".tr,
            value: controller.userAccount.value.isEmpty
                ? "not_set".tr
                : controller.userAccount.value,
            onTap: isGuest ? null : controller.updateAccount,
          ),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.mail_solid,
            label: "email_label".tr,
            value: controller.userEmail.value.isEmpty
                ? "not_set".tr
                : controller.userEmail.value,
            onTap: isGuest ? null : controller.updateEmail,
          ),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.phone_fill,
            label: "phone_label".tr,
            value: controller.userPhone.value.isEmpty
                ? "not_available".tr
                : controller.userPhone.value,
          ),
          _buildJobBioRow(context, isGuest: isGuest),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.paintbrush_fill,
            label: "color_label".tr,
            trailing: _ProfileColorValue(
              color: controller.userColor,
              label: colorHex,
            ),
            onTap: isGuest
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    controller.updateColor();
                  },
          ),
        ],
      );
    });
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              _fieldBadge(theme, icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null)
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
                )
              else
                Flexible(
                  child: Text(
                    value ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Job & Bio gets its own two-line layout (job on the label line's right,
  /// the bio itself as a full-width paragraph underneath) — the bio reads
  /// far better left-aligned across the row's width than squeezed into a
  /// narrow right-aligned column next to a chevron.
  Widget _buildJobBioRow(BuildContext context, {required bool isGuest}) {
    final theme = Theme.of(context);
    final hasJob = controller.userJob.value.isNotEmpty;
    final hasBio = controller.userBio.value.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isGuest ? null : controller.updateJobAndBio,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _fieldBadge(theme, CupertinoIcons.briefcase_fill),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "job_bio_label".tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      hasJob ? controller.userJob.value : "not_set".tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (!isGuest) ...[
                    const SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
              if (hasBio) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    controller.userBio.value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Same neutral glass icon badge used by the Settings drawer rows. The
  /// user-selected profile color stays scoped to the identity card above.
  Widget _fieldBadge(ThemeData theme, IconData icon) {
    return CustomGlassContainer(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      borderRadius: 10,
      glassColor: theme.colorScheme.surfaceContainerHighest,
      opacity: 0.5,
      blur: 8,
      child: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
    );
  }

  /// Modern grid showing some account "stats" or activity highlights.
  Widget _buildStatsGrid(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            title: "joined_label".tr,
            value: "Aug 2026",
            icon: CupertinoIcons.calendar,
            accent: accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            context,
            title: "tier_label".tr,
            value: "profile_tier_free".tr,
            icon: CupertinoIcons.star_fill,
            accent: accent,
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
    required Color accent,
  }) {
    final theme = Theme.of(context);
    return CustomGlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent.withValues(alpha: 0.7)),
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

  /// Log Out / Delete Account use the same flat drawer-row language as Basic
  /// Information so the whole lower half of the screen feels consistent.
  Widget _buildActionsCard(BuildContext context) {
    return Obx(() {
      final isGuest = controller.isGuestMode.value;
      final rows = <Widget>[_buildAccountActionRow(context)];
      if (!isGuest) rows.add(_buildDeleteAccountRow(context));

      return Column(children: rows);
    });
  }

  Widget _buildAccountActionRow(BuildContext context) {
    final isGuest = controller.isGuestMode.value;
    return _buildActionRow(
      context,
      icon: isGuest
          ? CupertinoIcons.arrow_right_circle
          : CupertinoIcons.square_arrow_right,
      title: isGuest ? "log_in_create_account".tr : "log_out".tr,
      onTap: () {
        HapticFeedback.mediumImpact();
        if (isGuest) {
          Get.offAllNamed(Routes.LOGIN);
        } else {
          unawaited(controller.logout());
        }
      },
    );
  }

  Widget _buildDeleteAccountRow(BuildContext context) {
    return _buildActionRow(
      context,
      icon: CupertinoIcons.trash_fill,
      title: "delete_account_title".tr,
      showChevron: true,
      onTap: () => Get.toNamed(Routes.ACCOUNT),
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showChevron = false,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
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
                glassColor: Colors.red,
                opacity: 0.12,
                blur: 8,
                child: Icon(icon, size: 18, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
              if (showChevron)
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: Colors.red.withValues(alpha: 0.55),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileColorValue extends StatelessWidget {
  final Color color;
  final String label;

  const _ProfileColorValue({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
