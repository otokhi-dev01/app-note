import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/services/auth_service.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/decorative_background.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../home/home_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      extendBodyBehindAppBar: true,
      appBar: CustomGlassAppBar(
        titleText: '${homeController.user.value?.fullName ?? 'User'}',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(),
        ),
      ),
      body: DecorativeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Obx(() {
              final user = homeController.user.value;
              return Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Hero(
                          tag: 'profile_avatar',
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primary,
                            backgroundImage: user?.avatar != null
                                ? NetworkImage(user!.avatar!)
                                : null,
                            child: user?.avatar == null
                                ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 60,
                            )
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    user?.fullName ?? 'Welcome',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? 'No phone linked',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTag('Pro Member', Icons.verified, Colors.teal),
                      const SizedBox(width: 12),
                      _buildTag('Synced', Icons.cloud_done, Colors.blueGrey),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildSectionTitle('ACCOUNT SETTINGS'),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    Icons.person_outline_rounded,
                    'Edit Profile',
                    'Update name, avatar, and contact info',
                  ),
                  _buildMenuItem(
                    Icons.lock_outline_rounded,
                    'Security',
                    'Password, 2FA, and active sessions',
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('PREFERENCES'),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    Icons.storage_outlined,
                    'Data & Storage',
                    'Manage backups and local storage',
                    trailing: '1.2 GB',
                  ),
                  _buildMenuItem(
                    Icons.help_outline_rounded,
                    'Help & Support',
                    'FAQs, contact support, guides',
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => authService.logout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon,
      String title,
      String subtitle, {
        String? trailing,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LiquidGlassContainer(
        borderRadius: BorderRadius.circular(20),
        opacity: 0.6,
        blur: 10,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null) ...[
                Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPlaceholder,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPlaceholder,
              ),
            ],
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
