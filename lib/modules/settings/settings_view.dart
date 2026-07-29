import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/services/auth_service.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/custom_app_bar.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with AutomaticKeepAliveClientMixin {
  // State variables for the toggles
  bool _pushNotifications = true;
  bool _emailSummaries = false;
  bool _darkMode = false;
  bool _compactView = false;
  bool _syncWifiOnly = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: CustomGlassAppBar(
        titleText: 'Settings',
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: 8),
        ],  bottom: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox(),)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage your preferences and app configurations.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),

            _buildSection('Notifications', [
              _buildSwitchItem(
                'Push Notifications',
                'Receive alerts on your device.',
                _pushNotifications,
                    (val) => setState(() => _pushNotifications = val),
              ),
              _buildSwitchItem(
                'Email Summaries',
                'Weekly digest of activity.',
                _emailSummaries,
                    (val) => setState(() => _emailSummaries = val),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSection('Appearance', [
              _buildSwitchItem(
                'Dark Mode',
                'Toggle dark theme.',
                _darkMode,
                    (val) => setState(() => _darkMode = val),
              ),
              _buildSwitchItem(
                'Compact View',
                'Reduce spacing in lists.',
                _compactView,
                    (val) => setState(() => _compactView = val),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSection('Sync Settings', [
              _buildSyncItem('Cloud Provider', 'Google Drive Connected', Icons.cloud_outlined),
              _buildSwitchItem(
                'Sync over Wi-Fi only',
                'Save mobile data.',
                _syncWifiOnly,
                    (val) => setState(() => _syncWifiOnly = val),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSection('About', [
              _buildAboutItem('Version', 'v2.4.1'),
              _buildAboutItem('Privacy Policy', '', showLink: true),
            ]),

            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.find<AuthService>().logout(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    // Automatically inject dividers between items for a cleaner look
    List<Widget> itemsWithDividers = [];
    for (int i = 0; i < children.length; i++) {
      itemsWithDividers.add(children[i]);
      if (i < children.length - 1) {
        itemsWithDividers.add(const Divider(
          height: 1,
          color: AppColors.border,
          indent: 16,
          endIndent: 16,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Row(
            children: [
              Icon(_getSectionIcon(title), size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        LiquidGlassContainer(
          borderRadius: BorderRadius.circular(16),
          opacity: 0.7,
          blur: 10,
          child: Column(children: itemsWithDividers),
        ),
      ],
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Notifications': return Icons.notifications_outlined;
      case 'Appearance': return Icons.palette_outlined;
      case 'Sync Settings': return Icons.sync_outlined;
      case 'About': return Icons.info_outline;
      default: return Icons.settings_outlined;
    }
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
      inactiveThumbColor: AppColors.textPlaceholder,
      inactiveTrackColor: AppColors.border,
    );
  }

  Widget _buildSyncItem(String title, String subtitle, IconData icon) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textPlaceholder),
      onTap: () {},
    );
  }

  Widget _buildAboutItem(String title, String value, {bool showLink = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      trailing: showLink
          ? const Icon(Icons.open_in_new, size: 18, color: AppColors.textPlaceholder)
          : Text(
        value,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: showLink ? () {} : null,
    );
  }
}