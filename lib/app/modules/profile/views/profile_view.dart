import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
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
                "Profile",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              largeTitlePadding: const EdgeInsets.fromLTRB(25, 0, 16, 12),
              largeTitle: Text(
                "Profile",
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Profile Image Section
                    Center(
                      child: Stack(
                        children: [
                          Obx(
                            () => Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.folderPink.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: Hero(
                                tag: 'profile_image',
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  backgroundImage:
                                      controller.userImagePath.value.isNotEmpty
                                      ? FileImage(
                                          File(controller.userImagePath.value),
                                        )
                                      : null,
                                  child: controller.userImagePath.value.isEmpty
                                      ? Icon(
                                          Icons.person_rounded,
                                          size: 60,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: AppTheme.folderPink,
                              shape: const CircleBorder(),
                              elevation: 4,
                              child: InkWell(
                                onTap: controller.updateProfileImage,
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // User Info Card
                    InkWell(
                      onTap: controller.updateUserName,
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          Obx(
                            () => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    controller.userName.value,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                          Obx(() {
                            final phone = controller.userPhone.value;
                            return Text(
                              phone,
                              style: theme.textTheme.bodyMedium,
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    // Appearance Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          "Appearance",
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 28),
                    CustomGlassContainer(
                      borderRadius: 30,
                      blur: 35,
                      opacity: 0.1,
                      thickness: 15,
                      showGlow: true,
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            _buildThemeOption(
                              context,
                              title: "System Default",
                              icon: Icons.brightness_auto_rounded,
                              mode: ThemeMode.system,
                            ),
                            const Divider(indent: 56, height: 1),
                            _buildThemeOption(
                              context,
                              title: "Light Mode",
                              icon: Icons.light_mode_rounded,
                              mode: ThemeMode.light,
                            ),
                            const Divider(indent: 56, height: 1),
                            _buildThemeOption(
                              context,
                              title: "Dark Mode",
                              icon: Icons.dark_mode_rounded,
                              mode: ThemeMode.dark,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Account Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          "Account",
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 28),
                    CustomGlassContainer(
                      borderRadius: 30,
                      blur: 35,
                      opacity: 0.1,
                      thickness: 15,
                      showGlow: true,
                      child: Material(
                        color: Colors.transparent,
                        child: CustomGlassListTile(
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
                          title: const Text(
                            "Sign Out",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.red,
                          ),
                        ),
                      ),
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
    final controller = Get.find<ProfileController>();

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
