import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Note/core/feedback/app_snackbar.dart';

/// External actions shared by the full-screen settings features.
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
      'action unavailable title'.tr,
      'action unavailable message'.tr,
    );
  }
}
