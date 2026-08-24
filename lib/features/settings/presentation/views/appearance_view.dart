import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/settings/presentation/controllers/appearance_controller.dart';

class AppearanceView extends GetView<AppearanceController> {
  const AppearanceView({super.key});

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
                "appearance_title".tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
              largeTitle: Text(
                "appearance_title".tr,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 34,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: GlassCard(
                  borderRadius: 28,
                  children: [
                    _buildThemeOption(
                      context,
                      title: "appearance_system_default".tr,
                      icon: Icons.brightness_auto_rounded,
                      mode: ThemeMode.system,
                    ),
                    const Divider(indent: 56, height: 1),
                    _buildThemeOption(
                      context,
                      title: "appearance_light_mode".tr,
                      icon: Icons.light_mode_rounded,
                      mode: ThemeMode.light,
                    ),
                    const Divider(indent: 56, height: 1),
                    _buildThemeOption(
                      context,
                      title: "dark_mode".tr,
                      icon: Icons.dark_mode_rounded,
                      mode: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode mode,
  }) {
    final theme = Theme.of(context);

    return Obx(() {
      final isSelected = controller.currentThemeMode.value == mode;
      return CustomGlassListTile(
        onTap: () => controller.changeTheme(mode),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.folderPink.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected
                ? AppTheme.folderPink
                : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppTheme.folderPink)
            : null,
      );
    });
  }
}
