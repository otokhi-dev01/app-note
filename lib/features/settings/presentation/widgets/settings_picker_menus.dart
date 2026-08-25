import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/settings_preferences.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/theme/app_theme.dart';

typedef SettingsMenuTriggerBuilder =
    Widget Function(BuildContext context, VoidCallback toggleMenu);

class DevicePickerMenu extends StatelessWidget {
  final SettingsMenuTriggerBuilder triggerBuilder;
  final bool morphFromZero;

  const DevicePickerMenu({
    super.key,
    required this.triggerBuilder,
    this.morphFromZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionStorage>();
    final guestMode = Get.find<GuestModeService>();
    final apiDeviceName = session.user.value?.deviceName?.trim() ?? '';
    final apiDeviceType = session.user.value?.deviceType?.trim() ?? '';
    final deviceName = apiDeviceName.isNotEmpty
        ? apiDeviceName
        : _platformDeviceName;
    final deviceType = apiDeviceType.isNotEmpty
        ? apiDeviceType
        : _platformDeviceName;
    final isCloudAccount = session.isLoggedIn && !guestMode.isGuestMode.value;

    return lg.GlassMenu(
      triggerBuilder: triggerBuilder,
      menuWidth: 310,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      morphFromZero: morphFromZero,
      items: [
        lg.GlassMenuLabel(title: 'device_title'.tr),
        lg.GlassMenuItem(
          title: 'device_current'.tr,
          subtitle: '$deviceName • $deviceType',
          icon: const Icon(Icons.phone_iphone_rounded),
          onTap: () {},
          trailing: Text(
            'device_this_device'.tr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.folderPink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const lg.GlassMenuDivider(),
        lg.GlassMenuItem(
          title: 'device_storage'.tr,
          subtitle: isCloudAccount
              ? 'device_storage_cloud_desc'.tr
              : 'device_storage_local_desc'.tr,
          icon: Icon(
            isCloudAccount
                ? Icons.cloud_done_rounded
                : Icons.phone_android_rounded,
          ),
          onTap: () {},
          trailing: Icon(
            isCloudAccount ? Icons.cloud_done_rounded : Icons.check_circle,
            color: AppTheme.folderPink,
            size: 20,
          ),
        ),
        lg.GlassMenuItem(
          title: 'device_account_status'.tr,
          subtitle: isCloudAccount
              ? 'device_account_synced'.tr
              : 'device_account_local'.tr,
          icon: Icon(
            isCloudAccount ? Icons.sync_rounded : Icons.cloud_off_outlined,
          ),
          onTap: () {},
        ),
      ],
    );
  }

  String get _platformDeviceName {
    if (Platform.isIOS) return 'device_platform_ios'.tr;
    if (Platform.isAndroid) return 'device_platform_android'.tr;
    if (Platform.isMacOS) return 'device_platform_macos'.tr;
    if (Platform.isWindows) return 'device_platform_windows'.tr;
    return 'device_platform_other'.tr;
  }
}

class NotificationPickerMenu extends StatefulWidget {
  final SettingsMenuTriggerBuilder triggerBuilder;
  final bool morphFromZero;

  const NotificationPickerMenu({
    super.key,
    required this.triggerBuilder,
    this.morphFromZero = false,
  });

  @override
  State<NotificationPickerMenu> createState() => _NotificationPickerMenuState();
}

class _NotificationPickerMenuState extends State<NotificationPickerMenu> {
  final _preferences = Get.find<SettingsPreferences>();

  @override
  Widget build(BuildContext context) {
    final confirmations = _preferences.actionConfirmations.value;

    return lg.GlassMenu(
      triggerBuilder: widget.triggerBuilder,
      menuWidth: 310,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      morphFromZero: widget.morphFromZero,
      items: [
        lg.GlassMenuLabel(title: 'notifications_title'.tr),
        lg.GlassMenuItem(
          title: 'notifications_confirmations'.tr,
          subtitle: 'notifications_confirmations_desc'.tr,
          icon: const Icon(Icons.notifications_active_outlined),
          height: 62,
          isSelected: confirmations,
          trailing: _statusText(context, confirmations),
          onTap: () {
            setState(() {
              _preferences.setActionConfirmations(!confirmations);
            });
          },
        ),
        const lg.GlassMenuDivider(),
        lg.GlassMenuItem(
          title: 'notifications_important'.tr,
          subtitle: 'notifications_important_desc'.tr,
          icon: const Icon(Icons.security_rounded),
          height: 62,
          isSelected: true,
          trailing: _statusText(context, true),
          onTap: () {},
        ),
      ],
    );
  }
}

class PrivacySecurityPickerMenu extends StatefulWidget {
  final SettingsMenuTriggerBuilder triggerBuilder;
  final bool morphFromZero;

  const PrivacySecurityPickerMenu({
    super.key,
    required this.triggerBuilder,
    this.morphFromZero = false,
  });

  @override
  State<PrivacySecurityPickerMenu> createState() =>
      _PrivacySecurityPickerMenuState();
}

class _PrivacySecurityPickerMenuState extends State<PrivacySecurityPickerMenu> {
  final _preferences = Get.find<SettingsPreferences>();

  @override
  Widget build(BuildContext context) {
    final hidePreviews = _preferences.hideNotePreviews.value;

    return lg.GlassMenu(
      triggerBuilder: widget.triggerBuilder,
      menuWidth: 330,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      morphFromZero: widget.morphFromZero,
      items: [
        lg.GlassMenuLabel(title: 'privacy_security_title'.tr),
        lg.GlassMenuItem(
          title: 'privacy_hide_previews'.tr,
          subtitle: 'privacy_hide_previews_desc'.tr,
          icon: Icon(
            hidePreviews
                ? Icons.visibility_off_rounded
                : Icons.visibility_outlined,
          ),
          height: 62,
          isSelected: hidePreviews,
          trailing: _statusText(context, hidePreviews),
          onTap: () {
            setState(() {
              _preferences.setHideNotePreviews(!hidePreviews);
            });
          },
        ),
        const lg.GlassMenuDivider(),
        lg.GlassMenuItem(
          title: 'privacy_secure_session'.tr,
          subtitle: 'privacy_secure_session_desc'.tr,
          icon: const Icon(Icons.enhanced_encryption_rounded),
          height: 62,
          isSelected: true,
          onTap: () {},
          trailing: const Icon(
            Icons.verified_user_rounded,
            color: AppTheme.folderPink,
            size: 20,
          ),
        ),
      ],
    );
  }
}

Widget _statusText(BuildContext context, bool enabled) {
  return Text(
    enabled ? 'settings_status_on'.tr : 'settings_status_off'.tr,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: enabled
          ? AppTheme.folderPink
          : Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    ),
  );
}

class HelpCenterPickerMenu extends StatelessWidget {
  final SettingsMenuTriggerBuilder triggerBuilder;
  final bool morphFromZero;

  const HelpCenterPickerMenu({
    super.key,
    required this.triggerBuilder,
    this.morphFromZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return lg.GlassMenu(
      triggerBuilder: triggerBuilder,
      menuWidth: 330,
      menuHeight: 440,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      morphFromZero: morphFromZero,
      items: [
        lg.GlassMenuLabel(title: 'help_center_title'.tr),
        for (var index = 1; index <= 4; index++) ...[
          lg.GlassMenuLabel(
            height: 130,
            horizontalPadding: 12,
            child: _FaqContent(
              question: 'help_center_faq_q$index'.tr,
              answer: 'help_center_faq_a$index'.tr,
            ),
          ),
          if (index < 4) const lg.GlassMenuDivider(),
        ],
      ],
    );
  }
}

class _FaqContent extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqContent({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          answer,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
