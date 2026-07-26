import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/services/auth_service.dart';
import '../../app/theme/colors.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const Hero(
                  tag: 'profile_avatar',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=eleanor'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Eleanor Vance', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_iphone, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 4),
                Text('+1 (555) 284-9102', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTag('Pro Member', Icons.verified, Colors.teal),
                const SizedBox(width: 12),
                _buildTag('Synced', Icons.cloud_done, Colors.blueGrey),
              ],
            ),
            const SizedBox(height: 40),
            _buildMenuItem(Icons.person_outline, 'Edit Profile', 'Update name, avatar, and contact info'),
            _buildMenuItem(Icons.lock_outline, 'Security', 'Password, 2FA, and active sessions'),
            _buildMenuItem(Icons.storage_outlined, 'Data & Storage', 'Manage backups and local storage', trailing: '1.2 GB'),
            _buildMenuItem(Icons.help_outline, 'Help', 'FAQs, contact support, guides'),
            const SizedBox(height: 40),
            OutlinedButton(
              onPressed: () => authService.logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: Color(0xFFFFEBEE)),
                backgroundColor: const Color(0xFFFFEBEE).withValues(alpha: 0.3),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {String? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (trailing != null) ...[
            Text(trailing, style: const TextStyle(fontSize: 12, color: AppColors.textPlaceholder)),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right, color: AppColors.textPlaceholder),
        ],
      ),
    );
  }
}
