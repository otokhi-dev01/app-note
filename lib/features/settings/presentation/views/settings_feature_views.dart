import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/storage/settings_preferences.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/settings/presentation/widgets/preference_actions.dart';
import 'package:Note/features/settings/presentation/widgets/settings_app_bar.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = Get.find<SettingsPreferences>();

    return _SettingsFeatureScaffold(
      title: 'notifications_title'.tr,
      useSurfaceBackButtonColor: true,
      child: Obx(
        () => _FeatureCard(
          children: [
            _FeatureTile(
              icon: CupertinoIcons.bell_fill,
              iconColor: IosSemanticColors.red,
              title: 'notifications_confirmations'.tr,
              subtitle: 'notifications_confirmations_desc'.tr,
              trailing: Switch.adaptive(
                value: preferences.actionConfirmations.value,
                onChanged: preferences.setActionConfirmations,
              ),
              onTap: () => preferences.setActionConfirmations(
                !preferences.actionConfirmations.value,
              ),
            ),
            _FeatureTile(
              icon: CupertinoIcons.exclamationmark_shield_fill,
              iconColor: IosSemanticColors.orange,
              title: 'notifications_important'.tr,
              subtitle: 'notifications_important_desc'.tr,
              trailing: _StatusLabel(enabled: true),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceSettingsView extends StatelessWidget {
  const DeviceSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionStorage>();
    final guestMode = Get.find<GuestModeService>();
    final apiDeviceName = session.user.value?.deviceName?.trim() ?? '';
    final apiDeviceType = session.user.value?.deviceType?.trim() ?? '';
    final platformName = _platformDeviceName;
    final deviceName = apiDeviceName.isEmpty ? platformName : apiDeviceName;
    final deviceType = apiDeviceType.isEmpty ? platformName : apiDeviceType;
    final isCloudAccount = session.isLoggedIn && !guestMode.isGuestMode.value;

    return _SettingsFeatureScaffold(
      title: 'device_title'.tr,
      useSurfaceBackButtonColor: true,
      child: _FeatureCard(
        children: [
          _FeatureTile(
            icon: CupertinoIcons.device_phone_portrait,
            iconColor: IosSemanticColors.gray,
            title: 'device_current'.tr,
            subtitle: '$deviceName • $deviceType',
            trailing: Text(
              'device_this_device'.tr,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: IosSemanticColors.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _FeatureTile(
            icon: isCloudAccount
                ? CupertinoIcons.cloud_fill
                : CupertinoIcons.device_phone_portrait,
            iconColor: isCloudAccount
                ? IosSemanticColors.blue
                : IosSemanticColors.gray,
            title: 'device_storage'.tr,
            subtitle: isCloudAccount
                ? 'device_storage_cloud_desc'.tr
                : 'device_storage_local_desc'.tr,
            trailing: const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: IosSemanticColors.green,
            ),
          ),
          _FeatureTile(
            icon: isCloudAccount
                ? CupertinoIcons.arrow_2_circlepath
                : Icons.cloud_off_rounded,
            iconColor: isCloudAccount
                ? IosSemanticColors.green
                : IosSemanticColors.gray,
            title: 'device_account_status'.tr,
            subtitle: isCloudAccount
                ? 'device_account_synced'.tr
                : 'device_account_local'.tr,
          ),
        ],
      ),
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

class LanguageSettingsView extends StatefulWidget {
  const LanguageSettingsView({super.key});

  @override
  State<LanguageSettingsView> createState() => _LanguageSettingsViewState();
}

class _LanguageSettingsViewState extends State<LanguageSettingsView> {
  final _preferences = LanguagePreferences();

  @override
  Widget build(BuildContext context) {
    final current = _preferences.language;

    return _SettingsFeatureScaffold(
      title: 'language_title'.tr,
      child: _FeatureCard(
        children: [
          for (final language in AppLanguage.values)
            _FeatureTile(
              leading: Text(
                language.flag,
                style: const TextStyle(fontSize: 28),
              ),
              title: language.label,
              trailing: language == current
                  ? const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: IosSemanticColors.blue,
                    )
                  : null,
              onTap: () {
                _preferences.setLanguage(language);
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}

class PrivacySecurityView extends StatelessWidget {
  const PrivacySecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = Get.find<SettingsPreferences>();

    return _SettingsFeatureScaffold(
      title: 'privacy_security_title'.tr,
      useSurfaceBackButtonColor: true,
      child: Obx(
        () => _FeatureCard(
          children: [
            _FeatureTile(
              icon: preferences.hideNotePreviews.value
                  ? CupertinoIcons.eye_slash_fill
                  : CupertinoIcons.eye_fill,
              iconColor: preferences.hideNotePreviews.value
                  ? IosSemanticColors.orange
                  : IosSemanticColors.blue,
              title: 'privacy_hide_previews'.tr,
              subtitle: 'privacy_hide_previews_desc'.tr,
              trailing: Switch.adaptive(
                value: preferences.hideNotePreviews.value,
                onChanged: preferences.setHideNotePreviews,
              ),
              onTap: () => preferences.setHideNotePreviews(
                !preferences.hideNotePreviews.value,
              ),
            ),
            _FeatureTile(
              icon: CupertinoIcons.lock_shield_fill,
              iconColor: IosSemanticColors.green,
              title: 'privacy_secure_session'.tr,
              subtitle: 'privacy_secure_session_desc'.tr,
              trailing: const Icon(
                CupertinoIcons.checkmark_shield_fill,
                color: IosSemanticColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsFeatureScaffold(
      title: 'privacy_policy_title'.tr,
      subtitle: 'privacy_policy_updated'.tr,
      useSurfaceBackButtonColor: true,
      child: _FeatureCard(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'privacy_policy_intro'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          _PolicySection(
            title: 'privacy_policy_data_title'.tr,
            body: 'privacy_policy_data_body'.tr,
          ),
          _PolicySection(
            title: 'privacy_policy_use_title'.tr,
            body: 'privacy_policy_use_body'.tr,
          ),
          _PolicySection(
            title: 'privacy_policy_permissions_title'.tr,
            body: 'privacy_policy_permissions_body'.tr,
          ),
          _PolicySection(
            title: 'privacy_policy_choices_title'.tr,
            body: 'privacy_policy_choices_body'.tr,
          ),
        ],
      ),
    );
  }
}

class ContactUsView extends StatelessWidget {
  const ContactUsView({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsFeatureScaffold(
      title: 'contact_us_title'.tr,
      subtitle: 'contact_us_subtitle'.tr,
      useSurfaceBackButtonColor: true,
      child: _FeatureCard(
        children: [
          _FeatureTile(
            icon: CupertinoIcons.phone_fill,
            iconColor: IosSemanticColors.green,
            title: 'contact_phone'.tr,
            subtitle: '${PreferenceActions.phoneNumber} • ${'tap_to_call'.tr}',
            showChevron: true,
            onTap: () => unawaited(PreferenceActions.callSupport()),
          ),
          _FeatureTile(
            icon: CupertinoIcons.mail_solid,
            iconColor: IosSemanticColors.blue,
            title: 'contact_email'.tr,
            subtitle:
                '${PreferenceActions.supportEmail} • ${'tap_to_email'.tr}',
            showChevron: true,
            onTap: () => unawaited(PreferenceActions.emailSupport()),
          ),
        ],
      ),
    );
  }
}

enum _PermissionKind { camera, photos, microphone }

class PermissionsView extends StatefulWidget {
  const PermissionsView({super.key});

  @override
  State<PermissionsView> createState() => _PermissionsViewState();
}

class _PermissionsViewState extends State<PermissionsView>
    with WidgetsBindingObserver {
  final Map<_PermissionKind, PermissionStatus> _statuses = {};
  final Set<_PermissionKind> _busy = {};
  bool _refreshing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  @override
  Widget build(BuildContext context) {
    final allowedCount = _statuses.values
        .where((status) => status.isGranted || status.isLimited)
        .length;

    return _SettingsFeatureScaffold(
      title: 'permissions_title'.tr,
      subtitle: 'permissions_subtitle'.tr,
      useSurfaceBackButtonColor: true,
      child: Column(
        children: [
          _PermissionOverview(
            allowedCount: allowedCount,
            loading: _refreshing,
            onRefresh: () => unawaited(_refresh()),
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            children: [
              _permissionTile(
                kind: _PermissionKind.camera,
                icon: CupertinoIcons.camera_fill,
                color: IosSemanticColors.blue,
                title: 'permissions_camera'.tr,
                subtitle: 'permissions_camera_desc'.tr,
              ),
              _permissionTile(
                kind: _PermissionKind.photos,
                icon: CupertinoIcons.photo_fill,
                color: IosSemanticColors.pink,
                title: 'permissions_photos'.tr,
                subtitle: 'permissions_photos_desc'.tr,
              ),
              _permissionTile(
                kind: _PermissionKind.microphone,
                icon: CupertinoIcons.mic_fill,
                color: IosSemanticColors.orange,
                title: 'permissions_microphone'.tr,
                subtitle: 'permissions_microphone_desc'.tr,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'permissions_tap_hint'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => unawaited(_openSettings()),
            icon: const Icon(CupertinoIcons.gear, size: 18),
            label: Text('open_app_settings'.tr),
          ),
        ],
      ),
    );
  }

  Widget _permissionTile({
    required _PermissionKind kind,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final status = _statuses[kind];
    final busy = _busy.contains(kind);
    return _FeatureTile(
      icon: icon,
      iconColor: color,
      title: title,
      subtitle: subtitle,
      trailing: busy || status == null
          ? const CupertinoActivityIndicator(radius: 9)
          : _PermissionStatus(status: status),
      onTap: status == null || status.isRestricted || busy
          ? null
          : () => unawaited(_handlePermission(kind, title)),
    );
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _refreshing = true);
    final statuses = await Future.wait([
      _readStatus(_PermissionKind.camera),
      _readStatus(_PermissionKind.photos),
      _readStatus(_PermissionKind.microphone),
    ]);
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      for (var index = 0; index < _PermissionKind.values.length; index++) {
        _statuses[_PermissionKind.values[index]] = statuses[index];
      }
    });
  }

  Future<PermissionStatus> _readStatus(_PermissionKind kind) async {
    try {
      return switch (kind) {
        _PermissionKind.camera => Permission.camera.status,
        _PermissionKind.microphone => Permission.microphone.status,
        _PermissionKind.photos => _readPhotoStatus(),
      };
    } catch (_) {
      return PermissionStatus.denied;
    }
  }

  Future<PermissionStatus> _readPhotoStatus() async {
    if (!Platform.isAndroid) return Permission.photos.status;

    final imageStatus = await Permission.photos.status;
    final videoStatus = await Permission.videos.status;
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted ||
        (imageStatus.isGranted && videoStatus.isGranted)) {
      return PermissionStatus.granted;
    }
    if (imageStatus.isLimited ||
        videoStatus.isLimited ||
        imageStatus.isGranted ||
        videoStatus.isGranted) {
      return PermissionStatus.limited;
    }
    if (imageStatus.isPermanentlyDenied ||
        videoStatus.isPermanentlyDenied ||
        storageStatus.isPermanentlyDenied) {
      return PermissionStatus.permanentlyDenied;
    }
    if (imageStatus.isRestricted ||
        videoStatus.isRestricted ||
        storageStatus.isRestricted) {
      return PermissionStatus.restricted;
    }
    return PermissionStatus.denied;
  }

  Future<void> _handlePermission(_PermissionKind kind, String name) async {
    final current = _statuses[kind];
    if (current == null || _busy.contains(kind) || current.isRestricted) return;
    if (current.isGranted || current.isLimited || current.isPermanentlyDenied) {
      await _openSettings();
      return;
    }

    setState(() => _busy.add(kind));
    PermissionStatus updated;
    try {
      updated = await _requestPermission(kind);
    } catch (_) {
      updated = PermissionStatus.denied;
    }
    if (!mounted) return;
    setState(() {
      _busy.remove(kind);
      _statuses[kind] = updated;
    });

    if (updated.isGranted || updated.isLimited) {
      AppSnackbar.success(
        'permissions_enabled_title'.tr,
        'permissions_enabled_message'.trParams({'permission': name}),
      );
    } else if (updated.isPermanentlyDenied) {
      AppSnackbar.warning(
        'permissions_blocked_title'.tr,
        'permissions_blocked_message'.tr,
      );
    }
  }

  Future<PermissionStatus> _requestPermission(_PermissionKind kind) async {
    switch (kind) {
      case _PermissionKind.camera:
        return Permission.camera.request();
      case _PermissionKind.microphone:
        return Permission.microphone.request();
      case _PermissionKind.photos:
        if (!Platform.isAndroid) return Permission.photos.request();
        await [Permission.photos, Permission.videos].request();
        var status = await _readPhotoStatus();
        if (status.isDenied) {
          await Permission.storage.request();
          status = await _readPhotoStatus();
        }
        return status;
    }
  }

  Future<void> _openSettings() async {
    try {
      if (!await openAppSettings()) _showUnavailable();
    } catch (_) {
      _showUnavailable();
    }
  }

  void _showUnavailable() {
    AppSnackbar.warning(
      'action_unavailable_title'.tr,
      'action_unavailable_message'.tr,
    );
  }
}

class _SettingsFeatureScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool useSurfaceBackButtonColor;

  const _SettingsFeatureScaffold({
    required this.title,
    required this.child,
    this.subtitle,
    this.useSurfaceBackButtonColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleText = subtitle;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SettingsSliverAppBar(
              title: title,
              useSurfaceBackButtonColor: useSurfaceBackButtonColor,
            ),
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (subtitleText != null) ...[
                          Text(
                            subtitleText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        child,
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
}

class _FeatureCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const _FeatureCard({required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    final divided = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        divided.add(
          Divider(
            height: 1,
            indent: padding == null ? 64 : 0,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        );
      }
      divided.add(children[index]);
    }

    return CustomGlassContainer(
      borderRadius: 22,
      blur: 20,
      opacity: 0.12,
      thickness: 8,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: divided,
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  const _FeatureTile({
    this.icon,
    this.iconColor,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
  }) : assert(icon != null || leading != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle;
    final trailingWidget = trailing;
    final tapCallback = onTap;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child:
                leading ??
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (iconColor ?? IosSemanticColors.blue).withValues(
                      alpha: 0.13,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 19, color: iconColor),
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitleText != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitleText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingWidget != null) ...[
            const SizedBox(width: 10),
            trailingWidget,
          ],
          if (showChevron) ...[
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 15,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ],
        ],
      ),
    );

    if (tapCallback == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          tapCallback();
        },
        child: content,
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final bool enabled;

  const _StatusLabel({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Text(
      enabled ? 'settings_status_on'.tr : 'settings_status_off'.tr,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: enabled
            ? IosSemanticColors.green
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionOverview extends StatelessWidget {
  final int allowedCount;
  final bool loading;
  final VoidCallback onRefresh;

  const _PermissionOverview({
    required this.allowedCount,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    const total = 3;
    final allAllowed = !loading && allowedCount == total;
    final color = allAllowed
        ? IosSemanticColors.green
        : IosSemanticColors.indigo;
    final summary = loading
        ? 'permissions_summary_loading'.tr
        : allAllowed
        ? 'permissions_summary_all'.tr
        : 'permissions_summary_count'.trParams({
            'allowed': '$allowedCount',
            'total': '$total',
          });

    return CustomGlassContainer(
      borderRadius: 20,
      blur: 20,
      opacity: 0.12,
      thickness: 8,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            allAllowed
                ? CupertinoIcons.checkmark_shield_fill
                : CupertinoIcons.shield_fill,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: loading ? null : allowedCount / total,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(4),
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: loading ? null : onRefresh,
            icon: loading
                ? const CupertinoActivityIndicator(radius: 9)
                : const Icon(CupertinoIcons.refresh),
          ),
        ],
      ),
    );
  }
}

class _PermissionStatus extends StatelessWidget {
  final PermissionStatus status;

  const _PermissionStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PermissionStatus.granted => (
        'permissions_status_allowed'.tr,
        IosSemanticColors.green,
      ),
      PermissionStatus.limited || PermissionStatus.provisional => (
        'permissions_status_limited'.tr,
        IosSemanticColors.orange,
      ),
      PermissionStatus.permanentlyDenied => (
        'permissions_status_settings'.tr,
        IosSemanticColors.red,
      ),
      PermissionStatus.restricted => (
        'permissions_status_restricted'.tr,
        IosSemanticColors.gray,
      ),
      PermissionStatus.denied => (
        'permissions_status_allow'.tr,
        IosSemanticColors.blue,
      ),
    };

    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
