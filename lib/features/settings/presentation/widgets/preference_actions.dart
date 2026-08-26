import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/profile/presentation/widgets/profile_glass_popup.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// Actions and glass popups shown in the Preferences section of the drawer.
class PreferenceActions {
  PreferenceActions._();

  static const phoneNumber = '+855 01561561';
  static const supportEmail = 'PIISIIT-offical@gmail.com';
  static final Uri _businessUri = Uri.parse('https://piisiit.com');

  static Future<void> shareApp(BuildContext context) async {
    final renderObject = context.findRenderObject();
    final origin = renderObject is RenderBox && renderObject.hasSize
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    try {
      await Share.share(
        'share_message'.tr,
        subject: 'Pii Note',
        sharePositionOrigin: origin,
      );
    } catch (_) {
      _showUnavailable();
    }
  }

  static Future<void> openBusiness() => _launch(_businessUri);

  static Future<void> callSupport() =>
      _launch(Uri(scheme: 'tel', path: phoneNumber.replaceAll(' ', '')));

  static Future<void> emailSupport() => _launch(
    Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': 'Pii Note Support'},
    ),
  );

  static Future<void> _launch(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: uri.scheme == 'https'
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
      if (!launched) _showUnavailable();
    } catch (_) {
      _showUnavailable();
    }
  }

  static void _showUnavailable() {
    AppSnackbar.warning(
      'action_unavailable_title'.tr,
      'action_unavailable_message'.tr,
    );
  }

  static Future<void> showPermissions(BuildContext context) {
    return ProfileGlassPopup.show<void>(
      context: context,
      maxWidth: 360,
      builder: (context) => const _PermissionsPanel(),
    );
  }

  static Future<void> _openSettings() async {
    try {
      if (!await openAppSettings()) _showUnavailable();
    } catch (_) {
      _showUnavailable();
    }
  }

  static Future<void> showPrivacyPolicy(BuildContext context) {
    return ProfileGlassPopup.show<void>(
      context: context,
      maxWidth: 440,
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
        return _PopupShell(
          icon: CupertinoIcons.doc_text_fill,
          iconColor: IosSemanticColors.purple,
          title: 'privacy_policy_title'.tr,
          subtitle: 'privacy_policy_updated'.tr,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight - 145),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'privacy_policy_intro'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> showContact(BuildContext context) {
    return ProfileGlassPopup.show<void>(
      context: context,
      maxWidth: 400,
      builder: (context) => _PopupShell(
        icon: CupertinoIcons.chat_bubble_2_fill,
        iconColor: IosSemanticColors.green,
        title: 'contact_us_title'.tr,
        subtitle: 'contact_us_subtitle'.tr,
        child: Column(
          children: [
            _InfoTile(
              icon: CupertinoIcons.phone_fill,
              iconColor: IosSemanticColors.green,
              title: 'contact_phone'.tr,
              subtitle: '$phoneNumber  •  ${'tap_to_call'.tr}',
              onTap: () => unawaited(callSupport()),
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: CupertinoIcons.mail_solid,
              iconColor: IosSemanticColors.blue,
              title: 'contact_email'.tr,
              subtitle: '$supportEmail  •  ${'tap_to_email'.tr}',
              onTap: () => unawaited(emailSupport()),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PermissionKind { camera, photos, microphone }

class _PermissionsPanel extends StatefulWidget {
  const _PermissionsPanel();

  @override
  State<_PermissionsPanel> createState() => _PermissionsPanelState();
}

class _PermissionsPanelState extends State<_PermissionsPanel>
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

  Future<void> _refresh() async {
    if (mounted) setState(() => _refreshing = true);
    final entries = await Future.wait([
      _readStatus(_PermissionKind.camera),
      _readStatus(_PermissionKind.photos),
      _readStatus(_PermissionKind.microphone),
    ]);
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      for (var index = 0; index < _PermissionKind.values.length; index++) {
        _statuses[_PermissionKind.values[index]] = entries[index];
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

    // Android 13+ splits images and videos into separate permissions, while
    // Android 12 and below use the legacy storage permission. Querying all
    // three lets one UI work correctly without guessing the device API level.
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
      await PreferenceActions._openSettings();
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
          // On Android 12 and below the modern media permissions are not
          // available, so fall back to READ_EXTERNAL_STORAGE.
          await Permission.storage.request();
          status = await _readPhotoStatus();
        }
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowedCount = _statuses.values
        .where((status) => status.isGranted || status.isLimited)
        .length;
    final maxContentHeight = (MediaQuery.sizeOf(context).height - 170).clamp(
      140.0,
      500.0,
    );

    return _PopupShell(
      icon: CupertinoIcons.checkmark_shield_fill,
      iconColor: IosSemanticColors.indigo,
      title: 'permissions_title'.tr,
      subtitle: 'permissions_subtitle'.tr,
      compact: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxContentHeight),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _PermissionOverview(
                allowedCount: allowedCount,
                totalCount: _PermissionKind.values.length,
                loading: _refreshing,
                onRefresh: () => unawaited(_refresh()),
              ),
              const SizedBox(height: 10),
              _buildTile(
                kind: _PermissionKind.camera,
                icon: CupertinoIcons.camera_fill,
                iconColor: IosSemanticColors.blue,
                title: 'permissions_camera'.tr,
                subtitle: 'permissions_camera_desc'.tr,
              ),
              const SizedBox(height: 7),
              _buildTile(
                kind: _PermissionKind.photos,
                icon: CupertinoIcons.photo_fill,
                iconColor: IosSemanticColors.pink,
                title: 'permissions_photos'.tr,
                subtitle: 'permissions_photos_desc'.tr,
              ),
              const SizedBox(height: 7),
              _buildTile(
                kind: _PermissionKind.microphone,
                icon: CupertinoIcons.mic_fill,
                iconColor: IosSemanticColors.orange,
                title: 'permissions_microphone'.tr,
                subtitle: 'permissions_microphone_desc'.tr,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 1),
                child: Text(
                  'permissions_tap_hint'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => unawaited(PreferenceActions._openSettings()),
                icon: const Icon(CupertinoIcons.gear, size: 17),
                label: Text('open_app_settings'.tr),
                style: TextButton.styleFrom(
                  foregroundColor: IosSemanticColors.blue,
                  minimumSize: const Size(44, 34),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required _PermissionKind kind,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final status = _statuses[kind];
    final busy = _busy.contains(kind);
    return _InfoTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      compact: true,
      onTap: status == null || status.isRestricted || busy
          ? null
          : () => unawaited(_handlePermission(kind, title)),
      // trailing: _PermissionStatusBadge(status: status, busy: busy),
    );
  }
}

class _PermissionOverview extends StatelessWidget {
  final int allowedCount;
  final int totalCount;
  final bool loading;
  final VoidCallback onRefresh;

  const _PermissionOverview({
    required this.allowedCount,
    required this.totalCount,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allAllowed = !loading && allowedCount == totalCount;
    final accent = allAllowed
        ? IosSemanticColors.green
        : IosSemanticColors.indigo;
    final progress = loading || totalCount == 0
        ? 0.0
        : allowedCount / totalCount;
    final summary = loading
        ? 'permissions_summary_loading'.tr
        : allAllowed
        ? 'permissions_summary_all'.tr
        : 'permissions_summary_count'.trParams({
            'allowed': '$allowedCount',
            'total': '$totalCount',
          });

    return CustomGlassContainer(
      borderRadius: 15,
      blur: 18,
      opacity: 0.11,
      thickness: 7,
      glassColor: accent.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 9, 7, 9),
        child: Row(
          children: [
            _GlassIcon(
              icon: allAllowed
                  ? CupertinoIcons.checkmark_shield_fill
                  : CupertinoIcons.shield_fill,
              color: accent,
              size: 34,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: loading ? null : progress,
                      minHeight: 4,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            CupertinoButton(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
              onPressed: loading ? null : onRefresh,
              child: loading
                  ? const CupertinoActivityIndicator(radius: 8)
                  : const Icon(CupertinoIcons.refresh, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// class _PermissionStatusBadge extends StatelessWidget {
//   final PermissionStatus? status;
//   final bool busy;

//   const _PermissionStatusBadge({required this.status, required this.busy});

//   @override
//   Widget build(BuildContext context) {
//     if (status == null || busy) {
//       return const SizedBox.square(
//         dimension: 22,
//         child: CupertinoActivityIndicator(radius: 9),
//       );
//     }

//     final (label, color, icon) = switch (status!) {
//       PermissionStatus.granted => (
//         'permissions_status_allowed'.tr,
//         IosSemanticColors.green,
//         CupertinoIcons.checkmark_circle_fill,
//       ),
//       PermissionStatus.limited || PermissionStatus.provisional => (
//         'permissions_status_limited'.tr,
//         IosSemanticColors.orange,
//         CupertinoIcons.circle_lefthalf_fill,
//       ),
//       PermissionStatus.permanentlyDenied => (
//         'permissions_status_settings'.tr,
//         IosSemanticColors.red,
//         CupertinoIcons.gear_alt_fill,
//       ),
//       PermissionStatus.restricted => (
//         'permissions_status_restricted'.tr,
//         IosSemanticColors.gray,
//         CupertinoIcons.lock_fill,
//       ),
//       PermissionStatus.denied => (
//         'permissions_status_allow'.tr,
//         IosSemanticColors.blue,
//         CupertinoIcons.plus_circle_fill,
//       ),
//     };

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.12),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 12),
//           const SizedBox(width: 3),
//           Text(
//             label,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: color,
//               fontWeight: FontWeight.w700,
//               fontSize: 10,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _PopupShell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;
  final bool compact;

  const _PopupShell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(16, 14, 16, 15)
            : const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassIcon(
                  icon: icon,
                  color: iconColor,
                  size: compact ? 42 : 48,
                ),
                SizedBox(width: compact ? 10 : 13),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              (compact
                                      ? theme.textTheme.titleMedium
                                      : theme.textTheme.titleLarge)
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: compact ? 11 : null,
                            height: compact ? 1.25 : 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: compact ? 5 : 8),
                CustomGlassButton(
                  width: compact ? 34 : 40,
                  height: compact ? 34 : 40,
                  minHeight: compact ? 34 : 40,
                  padding: EdgeInsets.zero,
                  borderRadius: 14,
                  semanticLabel: 'close',
                  onPressed: () => Navigator.of(context).pop(),
                  foregroundColor: IosSemanticColors.gray,
                  child: const Icon(CupertinoIcons.xmark, size: 17),
                ),
              ],
            ),
            SizedBox(height: compact ? 13 : 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _GlassIcon({required this.icon, required this.color, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return CustomGlassContainer(
      width: size,
      height: size,
      borderRadius: 15,
      blur: 18,
      opacity: 0.3,
      thickness: 8,
      glassColor: color.withValues(alpha: 0.82),
      glowIntensity: 0.18,
      child: Icon(icon, size: size <= 36 ? 18 : 21, color: Colors.white),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.compact = false,
  }) : trailing = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return CustomGlassContainer(
      borderRadius: compact ? 14 : 17,
      blur: 18,
      opacity: 0.1,
      thickness: 7,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(compact ? 9 : 12),
            child: Row(
              children: [
                _GlassIcon(
                  icon: icon,
                  color: iconColor,
                  size: compact ? 36 : 42,
                ),
                SizedBox(width: compact ? 9 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 13 : null,
                        ),
                      ),
                      SizedBox(height: compact ? 1 : 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: compact ? 10.5 : null,
                          height: compact ? 1.2 : 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  final bool showDivider;

  const _PolicySection({
    required this.title,
    required this.body,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (showDivider) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}
