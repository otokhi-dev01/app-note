import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/settings/presentation/controllers/account_controller.dart';
import 'package:Note/features/settings/presentation/widgets/account_delete_menu.dart';

class AccountView extends GetView<AccountController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            CustomGlassSliverAppBar(
              expandedHeight: 120,
              toolbarHeight: 56,
              padding: const EdgeInsets.symmetric(horizontal: 13),
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
                "account_title".tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
              largeTitle: Text(
                "account_title".tr,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 34,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Obx(
                  () => controller.isGuestMode.value
                      ? _buildGuestCard(context)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSignedInCard(context),
                            const SizedBox(height: 28),
                            _buildDeleteAccountSection(context),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    return GlassCard(
      borderRadius: 28,
      children: [
        CustomGlassListTile(
          onTap: controller.goToLogin,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.folderPink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.login_rounded,
              color: AppTheme.folderPink,
              size: 20,
            ),
          ),
          title: Text(
            "log_in_create_account".tr,
            style: const TextStyle(
              color: AppTheme.folderPink,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_forward,
            color: AppTheme.folderPink,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildSignedInCard(BuildContext context) {
    return GlassCard(
      borderRadius: 28,
      children: [
        CustomGlassListTile(
          onTap: controller.logout,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
          title: Text(
            "log_out".tr,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_forward,
            color: Colors.red,
            size: 18,
          ),
        ),
      ],
    );
  }

  /// Its own group, separate from Sign Out — deleting the account is a
  /// different order of consequence and Apple's guideline 5.1.1(v) wants it
  /// reachable without being mistakable for signing out.
  Widget _buildDeleteAccountSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          borderRadius: 28,
          children: [
            AccountDeleteMenu(
              controller: controller,
              triggerBuilder: (context, openMenu) => CustomGlassListTile(
                onTap: openMenu,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.delete_solid,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  "delete_account_title".tr,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  CupertinoIcons.chevron_forward,
                  color: Colors.red,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 12, top: 8),
          child: Text(
            "account_delete_account_desc".tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.6,
              ),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
