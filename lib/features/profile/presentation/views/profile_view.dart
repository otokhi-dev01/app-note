import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/features/profile/presentation/widgets/profile_more_popup.dart';
import 'package:Note/features/settings/presentation/controllers/account_controller.dart';
import 'package:Note/features/settings/presentation/widgets/account_delete_menu.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// The user's profile and account details.
///
/// Identity, editable information, and account actions have distinct visual
/// hierarchy while keeping all existing profile editing flows intact.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  static const _contentMaxWidth = 680.0;

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
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIdentityCard(context),
                        const SizedBox(height: 28),
                        _buildSectionLabel(context, 'profile_basic_info'.tr),
                        const SizedBox(height: 8),
                        _buildDetailsCard(context),
                        const SizedBox(height: 28),
                        _buildSectionLabel(context, 'account_label'.tr),
                        const SizedBox(height: 8),
                        _buildActionsCard(context),
                      ],
                    ),
                  ),
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
        semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Get.back(),
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        padding: EdgeInsets.zero,
        foregroundColor: theme.colorScheme.primary,
        child: const Icon(CupertinoIcons.chevron_left, size: 23),
      ),
      actions: [
        Obx(() {
          final isGuest = controller.isGuestMode.value;

          if (isGuest) return const SizedBox.square(dimension: 44);

          return ProfileMorePopup(
            controller: controller,
            triggerBuilder: (context, toggleMenu) => CustomGlassButton(
              semanticLabel: 'note_list_more_options'.tr,
              onPressed: toggleMenu,
              width: 44,
              height: 44,
              shape: GlassShape.circle,
              blur: 10,
              opacity: 0.15,
              thickness: 8,
              glassColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil, size: 19),
            ),
          );
        }),
      ],
      title: Text(
        'profile_title'.tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Obx(() {
      final isGuest = controller.isGuestMode.value;
      final imagePath = controller.userImagePath.value;
      final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();
      final accent = controller.userColor;
      final accentText =
          theme.brightness == Brightness.light &&
              accent.computeLuminance() > 0.45
          ? Color.lerp(accent, Colors.black, 0.42)!
          : accent;
      final username = controller.userUsername.value;
      final account = controller.userAccount.value;
      final status = isGuest
          ? 'guest_status'.tr
          : (account.isEmpty ? 'account_label'.tr : account);

      return CustomGlassContainer(
        width: double.infinity,
        borderRadius: 24,
        blur: 24,
        opacity: 0.12,
        thickness: 10,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.14),
                      scheme.surface.withValues(alpha: 0.62),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -38,
              top: -48,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              child: SizedBox(
                width: double.infinity,
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
                            color: scheme.surface,
                            border: Border.all(
                              color: accent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 39,
                            backgroundColor: scheme.surfaceContainerHighest,
                            backgroundImage: hasImage
                                ? FileImage(File(imagePath))
                                : null,
                            child: hasImage
                                ? null
                                : Icon(
                                    CupertinoIcons.person_fill,
                                    color: accentText,
                                    size: 37,
                                  ),
                          ),
                        ),
                        if (!isGuest)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: CustomGlassButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                controller.updateProfileImage();
                              },
                              semanticLabel: 'profile_image_updated_message'.tr,
                              width: 30,
                              height: 30,
                              shape: GlassShape.circle,
                              blur: 8,
                              opacity: 0.2,
                              thickness: 5,
                              glassColor: accent,
                              foregroundColor: AppColors.onAccent(accent),
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.camera_fill,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      controller.userName.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (!isGuest && username.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 230),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accentText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accentText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Obx(() {
      final isGuest = controller.isGuestMode.value;
      final colorHex =
          controller.userColorHex.value ?? FolderAppearance.defaultColorValue;

      return _buildSurfaceCard(
        context,
        children: [
          _buildDetailRow(
            context,
            icon: CupertinoIcons.person_fill,
            label: 'full_name_label'.tr,
            value: controller.userName.value,
            onTap: isGuest ? null : controller.updateUserName,
          ),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.at,
            label: 'username_label'.tr,
            value: controller.userUsername.value.isEmpty
                ? 'not_set'.tr
                : '@${controller.userUsername.value}',
            onTap: isGuest ? null : controller.updateUsername,
          ),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.person_crop_circle_fill,
            label: 'account_label'.tr,
            value: controller.userAccount.value.isEmpty
                ? 'not_set'.tr
                : controller.userAccount.value,
            onTap: isGuest ? null : controller.updateAccount,
          ),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.mail_solid,
            label: 'email_label'.tr,
            value: controller.userEmail.value.isEmpty
                ? 'not_set'.tr
                : controller.userEmail.value,
            onTap: isGuest ? null : controller.updateEmail,
          ),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.phone_fill,
            label: 'phone_label'.tr,
            value: controller.userPhone.value.isEmpty
                ? 'not_available'.tr
                : controller.userPhone.value,
          ),
          _buildJobBioRow(context, isGuest: isGuest),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.paintbrush_fill,
            label: 'color_label'.tr,
            trailing: _ProfileColorValue(
              color: controller.userColor,
              label: colorHex,
            ),
            onTap: isGuest ? null : controller.updateColor,
          ),
        ],
      );
    });
  }

  Widget _buildSurfaceCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final groupedChildren = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        groupedChildren.add(
          Divider(
            height: 1,
            indent: 60,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        );
      }
      groupedChildren.add(children[index]);
    }

    return CustomGlassContainer(
      borderRadius: 20,
      blur: 20,
      opacity: 0.12,
      thickness: 8,
      clipBehavior: Clip.antiAlias,
      child: Column(children: groupedChildren),
    );
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
              _fieldBadge(theme, icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child:
                      trailing ??
                      Text(
                        value ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 7),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.48,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobBioRow(BuildContext context, {required bool isGuest}) {
    final theme = Theme.of(context);
    final hasJob = controller.userJob.value.isNotEmpty;
    final hasBio = controller.userBio.value.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isGuest
            ? null
            : () {
                HapticFeedback.selectionClick();
                controller.updateJobAndBio();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _fieldBadge(theme, CupertinoIcons.briefcase_fill),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'job_bio_label'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      hasJob ? controller.userJob.value : 'not_set'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (!isGuest) ...[
                    const SizedBox(width: 7),
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.48,
                      ),
                    ),
                  ],
                ],
              ),
              if (hasBio) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 48, right: 20),
                  child: Text(
                    controller.userBio.value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
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

  Widget _fieldBadge(ThemeData theme, IconData icon) {
    final scheme = theme.colorScheme;
    return CustomGlassContainer(
      width: 36,
      height: 36,
      borderRadius: 10,
      blur: 12,
      opacity: 0.12,
      thickness: 6,
      refractiveIndex: 1.1,
      glassColor: scheme.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: scheme.primary),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Obx(() {
      final isGuest = controller.isGuestMode.value;

      return _buildSurfaceCard(
        context,
        children: [
          _buildAccountActionRow(context, isGuest: isGuest),
          if (!isGuest) _buildDeleteAccountRow(context),
        ],
      );
    });
  }

  Widget _buildAccountActionRow(BuildContext context, {required bool isGuest}) {
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
        if (isGuest) {
          Get.offAllNamed(Routes.LOGIN);
        } else {
          unawaited(controller.logout());
        }
      },
    );
  }

  Widget _buildDeleteAccountRow(BuildContext context) {
    final accountController = AccountController(
      logout: Get.find<Logout>(),
      deleteAccount: Get.find<DeleteAccount>(),
      guestMode: Get.find<GuestModeService>(),
    );

    return AccountDeleteMenu(
      controller: accountController,
      morphFromZero: true,
      triggerBuilder: (context, openMenu) => _buildActionRow(
        context,
        icon: CupertinoIcons.trash_fill,
        title: 'delete_account_title'.tr,
        isDestructive: true,
        showChevron: true,
        onTap: openMenu,
      ),
    );
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
              CustomGlassContainer(
                width: 36,
                height: 36,
                borderRadius: 10,
                blur: 12,
                opacity: 0.12,
                thickness: 6,
                refractiveIndex: 1.1,
                glassColor: color.withValues(alpha: 0.1),
                alignment: Alignment.center,
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
            border: Border.all(color: theme.colorScheme.surface, width: 2),
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
