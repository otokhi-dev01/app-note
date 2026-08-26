import 'dart:async';

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
      maxWidth: 400,
      builder: (context) => _PopupShell(
        icon: CupertinoIcons.checkmark_shield_fill,
        iconColor: IosSemanticColors.indigo,
        title: 'permissions_title'.tr,
        subtitle: 'permissions_subtitle'.tr,
        child: Column(
          children: [
            _InfoTile(
              icon: CupertinoIcons.camera_fill,
              iconColor: IosSemanticColors.blue,
              title: 'permissions_camera'.tr,
              subtitle: 'permissions_camera_desc'.tr,
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: CupertinoIcons.photo_fill,
              iconColor: IosSemanticColors.pink,
              title: 'permissions_photos'.tr,
              subtitle: 'permissions_photos_desc'.tr,
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: CupertinoIcons.mic_fill,
              iconColor: IosSemanticColors.orange,
              title: 'permissions_microphone'.tr,
              subtitle: 'permissions_microphone_desc'.tr,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: CustomGlassButton(
                semanticLabel: 'open_app_settings'.tr,
                onPressed: () => unawaited(_openSettings()),
                glassColor: IosSemanticColors.blue.withValues(alpha: 0.82),
                foregroundColor: Colors.white,
                child: Text('open_app_settings'.tr),
              ),
            ),
          ],
        ),
      ),
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

class _PopupShell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _PopupShell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassIcon(icon: icon, color: iconColor, size: 48),
                const SizedBox(width: 13),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CustomGlassButton(
                  width: 40,
                  height: 40,
                  minHeight: 40,
                  padding: EdgeInsets.zero,
                  borderRadius: 14,
                  semanticLabel: 'close',
                  onPressed: () => Navigator.of(context).pop(),
                  foregroundColor: IosSemanticColors.gray,
                  child: const Icon(CupertinoIcons.xmark, size: 17),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
      child: Icon(icon, size: 21, color: Colors.white),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return CustomGlassContainer(
      borderRadius: 17,
      blur: 18,
      opacity: 0.1,
      thickness: 7,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _GlassIcon(icon: icon, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
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
