import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark 
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent) 
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // SliverAppBar with Dynamic Title Transition (Large to Small)
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              expandedHeight: 140.0,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: true,
              systemOverlayStyle: isDark 
                  ? SystemUiOverlayStyle.light 
                  : SystemUiOverlayStyle.dark,
              // Centered small title (visible when collapsed)
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final double percentage = (constraints.maxHeight - kToolbarHeight) / (140.0 - kToolbarHeight);
                  final opacity = (1.0 - percentage).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity > 0.8 ? 1.0 : 0.0,
                    child: Text(
                      "Profile",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                  );
                },
              ),
              leading: Center(
                child: LiquidGlassContainer(
                  width: 44,
                  height: 44,
                  shape: GlassShape.circle,
                  showGlow: true,
                  thickness: 8,
                  refractiveIndex: 1.1,
                  opacity: 0.15, // Standard glass icon opacity
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.chevron_left, 
                      color: theme.colorScheme.onSurface, 
                      size: 28,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              leadingWidth: 70,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final double percentage = (constraints.maxHeight - kToolbarHeight) / (140.0 - kToolbarHeight);
                    return Opacity(
                      opacity: percentage.clamp(0.0, 1.0),
                      child: Text(
                        "Profile",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Scrollable Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // User Avatar & Info
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: controller.updateProfileImage,
                            child: Stack(
                              children: [
                                Obx(() => Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.primaryColor,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.black26 : Colors.black12,
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: controller.userImagePath.value.isEmpty
                                      ? Center(
                                          child: Icon(
                                            Icons.person_rounded,
                                            size: 60,
                                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(60),
                                          child: Image.file(
                                            File(controller.userImagePath.value),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  size: 60,
                                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                )),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: controller.updateUserName,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Obx(() => Text(
                                  controller.userName.value,
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                )),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                          Obx(() => Text(
                            controller.userPhone.value,
                            style: theme.textTheme.bodyMedium,
                          )),
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
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    
                    GlassCard(
                      borderRadius: 30,
                      children: [
                        _buildThemeOption(context, "Light Mode", Icons.light_mode_outlined, ThemeMode.light),
                        Divider(indent: 56, height: 1, color: theme.dividerColor),
                        _buildThemeOption(context, "Dark Mode", Icons.dark_mode_outlined, ThemeMode.dark),
                        Divider(indent: 56, height: 1, color: theme.dividerColor),
                        _buildThemeOption(context, "System Default", Icons.settings_brightness_outlined, ThemeMode.system),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    // Account Section
                    GlassCard(
                      borderRadius: 30,
                      children: [
                        ListTile(
                          onTap: controller.logout,
                          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                          title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 60), // Extra bottom spacing
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, IconData icon, ThemeMode mode) {
    final theme = Theme.of(context);
    return Obx(() {
      final isSelected = controller.currentThemeMode.value == mode;
      
      return ListTile(
        onTap: () => controller.changeTheme(mode),
        leading: Icon(
          icon, 
          color: isSelected ? theme.primaryColor : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title, 
          style: theme.textTheme.bodyLarge,
        ),
        trailing: isSelected 
            ? Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.folderPink,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            : null,
      );
    });
  }
}
