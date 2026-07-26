import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/services/auth_service.dart';
import '../../app/theme/colors.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage your preferences and app configurations.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildSection('Notifications', [
              _buildSwitchItem('Push Notifications', 'Receive alerts on your device.', true),
              _buildSwitchItem('Email Summaries', 'Weekly digest of activity.', false),
            ]),
            const SizedBox(height: 24),
            _buildSection('Appearance', [
              _buildSwitchItem('Dark Mode', 'Toggle dark theme.', false),
              _buildSwitchItem('Compact View', 'Reduce spacing in lists.', false),
            ]),
            const SizedBox(height: 24),
            _buildSection('Sync Settings', [
              _buildSyncItem('Cloud Provider', 'Google Drive Connected', Icons.cloud_outlined),
              _buildSwitchItem('Sync over Wi-Fi only', 'Save mobile data.', true),
            ]),
            const SizedBox(height: 24),
            _buildSection('About', [
              _buildAboutItem('Version', 'v2.4.1'),
              _buildAboutItem('Privacy Policy', '', showLink: true),
            ]),
            const SizedBox(height: 40),
            Center(
              child: TextButton(
                onPressed: () => Get.find<AuthService>().logout(),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEBEE),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_getSectionIcon(title), size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Notifications': return Icons.notifications_none;
      case 'Appearance': return Icons.palette_outlined;
      case 'Sync Settings': return Icons.sync;
      case 'About': return Icons.info_outline;
      default: return Icons.settings_outlined;
    }
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: (_) {},
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildSyncItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  Widget _buildAboutItem(String title, String value, {bool showLink = false}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: showLink 
        ? const Icon(Icons.open_in_new, size: 18, color: AppColors.textPlaceholder) 
        : Text(value, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
