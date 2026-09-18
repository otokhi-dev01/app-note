import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/feedback/app_snackbar.dart';

// Palette for the Digital Civic ID flow. Kept distinct from the credit-card
// scan flow's palette (see card_flow_widgets.dart) since this is a
// government-ID styled surface: navy/ink, gold "sealed" accents, and a
// verified green rather than the card flow's blue.
const idInk = Color(0xFF10151C);
const idNavy = Color(0xFF15212C);
const idNavyLight = Color(0xFF1F2E3D);
const idAccent = Color(0xFF2F8FE0);
const idGreen = Color(0xFF1FAE64);
const idAmber = Color(0xFFC08A26);
const idMuted = Color(0xFF8A93A3);
const idBorder = Color(0xFFE7EAEE);

/// Light page background for the camera capture screen — the viewfinder
/// itself stays dark (idInk/idNavy), but the surrounding chrome (toolbar,
/// tabs, controls) sits on this pale lavender-gray rather than on idNavy.
const idScreenBg = Color(0xFFF2F1F7);

/// The persistent bilingual brand header shown at the top of every screen in
/// the identity scan flow: a back chevron, the section title with a live
/// status dot, and a shortcut into the camera scan flow.
class IdentityAppHeader extends StatelessWidget {
  const IdentityAppHeader({super.key, this.onBackTap, this.onCameraTap});

  final VoidCallback? onBackTap;
  final VoidCallback? onCameraTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: idBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          child: Row(
            children: [
              IconButton(
                onPressed: onBackTap,
                icon: const Icon(CupertinoIcons.back, color: idInk, size: 22),
              ),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'identity_app_title'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: idInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: idGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 1,
                shadowColor: Colors.black26,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onCameraTap,
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      CupertinoIcons.camera_fill,
                      color: idInk,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The success/pending banner ("Sealed" once both sides are verified).
class IdentityStatusBanner extends StatelessWidget {
  const IdentityStatusBanner({super.key, required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? idGreen : idMuted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: verified
            ? idGreen.withValues(alpha: 0.1)
            : idBorder.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: verified ? idGreen.withValues(alpha: 0.25) : idBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              verified
                  ? CupertinoIcons.checkmark_alt
                  : CupertinoIcons.doc_text_viewfinder,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified
                      ? 'identity_verified_title'.tr
                      : 'identity_pending_title'.tr,
                  style: const TextStyle(
                    color: idInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  verified
                      ? 'identity_verified_subtitle'.tr
                      : 'identity_pending_subtitle'.tr,
                  style: const TextStyle(color: idMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (verified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: idGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.lock_fill, size: 11, color: idInk),
                  const SizedBox(width: 4),
                  Text(
                    'identity_sealed_badge'.tr,
                    style: const TextStyle(
                      color: idInk,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class IdentitySectionHeader extends StatelessWidget {
  const IdentitySectionHeader({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: idInk),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: idInk,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// A small colored pill used for status tags ("CHIP MATCHED", "OCR V2.4",
/// "SHA-256", "VALID (10 YEARS)"...).
class IdentityTag extends StatelessWidget {
  const IdentityTag(this.label, {super.key, this.color = idAccent, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// A bordered card wrapping one OCR'd field: a bilingual caption, an
/// optional status tag, and the value widget.
class IdentityFieldCard extends StatelessWidget {
  const IdentityFieldCard({
    super.key,
    required this.label,
    required this.child,
    this.leadingIcon,
    this.tag,
  });

  final String label;
  final Widget child;
  final IconData? leadingIcon;
  final Widget? tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: idBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 14, color: idMuted),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: idMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ?tag,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// The National ID Number field's value: a large monospace-ish number with a
/// one-tap copy action.
class IdentityCopyableValue extends StatelessWidget {
  const IdentityCopyableValue(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: idInk,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Material(
          color: const Color(0xFFF1F2F5),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              unawaited(Clipboard.setData(ClipboardData(text: value)));
              AppSnackbar.success(
                'identity_copied_title'.tr,
                'identity_copied_message'.tr,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.doc_on_doc, size: 13, color: idInk),
                  const SizedBox(width: 5),
                  Text(
                    'identity_copy_action'.tr,
                    style: const TextStyle(
                      color: idInk,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One of the two scanned card thumbnails (front/back) on the result screen.
class IdentityPreviewCard extends StatelessWidget {
  const IdentityPreviewCard({
    super.key,
    required this.label,
    this.imagePath,
    this.front = true,
  });

  final String label;
  final String? imagePath;

  /// Which side this preview represents — used only to pick the placeholder
  /// mockup's look (a light "FRONT" photo mock vs. a dark "REAR" barcode
  /// mock) when there's no captured [imagePath] yet.
  final bool front;

  bool get _hasImage =>
      imagePath != null &&
      imagePath!.isNotEmpty &&
      File(imagePath!).existsSync();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.52,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _hasImage
                        ? const Color(0xFFF0F3F7)
                        : (front ? idGreen.withValues(alpha: 0.1) : idInk),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hasImage
                          ? idBorder
                          : (front ? idGreen.withValues(alpha: 0.25) : idInk),
                    ),
                    image: _hasImage
                        ? DecorationImage(
                            image: FileImage(File(imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _hasImage ? null : _placeholderMock(),
                ),
              ),
              if (_hasImage)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: idGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: idInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_hasImage) ...[
              const SizedBox(width: 4),
              const Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                size: 13,
                color: idGreen,
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// A drawn stand-in for the not-yet-captured photo: a small "FRONT"/"REAR"
  /// chip plus either a face silhouette with skeleton lines (front) or a
  /// barcode-style pattern (rear), so the two placeholders read distinctly
  /// even before either side has been scanned.
  Widget _placeholderMock() {
    final label = (front ? 'identity_side_front'.tr : 'identity_side_back'.tr)
        .toUpperCase();
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (front)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: idInk,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            )
          else
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          const Spacer(),
          if (front)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: idGreen.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.person_fill,
                    size: 14,
                    color: idGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _skeletonLine(width: double.infinity),
                      const SizedBox(height: 5),
                      _skeletonLine(width: 40),
                    ],
                  ),
                ),
              ],
            )
          else
            SizedBox(
              height: 22,
              child: Row(
                children: List.generate(14, (i) {
                  final tall = i.isEven;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.6),
                      height: tall ? 22 : 12,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.6),
                        height: tall ? 22 : 12,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _skeletonLine({required double width}) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: idGreen.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// The encrypted MRZ / chip-signature block shown at the bottom of the ID
/// information list.
class IdentityMrzBlock extends StatelessWidget {
  const IdentityMrzBlock({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: idInk,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.lock_shield,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'identity_mrz_title'.tr.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const IdentityTag('SHA-256'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${'identity_mrz_signature_comment'.tr}\n${lines.join('\n')}',
            style: const TextStyle(
              color: Color(0xFF7FE0B8),
              fontFamily: 'monospace',
              fontSize: 12,
              letterSpacing: 1.1,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

/// Black, full-width primary action ("Confirm & Continue").
class IdentityPrimaryButton extends StatelessWidget {
  const IdentityPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = CupertinoIcons.checkmark_alt,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: idInk,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Bordered secondary action ("Rescan Card").
class IdentitySecondaryButton extends StatelessWidget {
  const IdentitySecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = CupertinoIcons.arrow_2_circlepath,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: idInk,
          side: const BorderSide(color: idBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Closing footer caption shown at the bottom of the result screen.
class IdentityFooterNote extends StatelessWidget {
  const IdentityFooterNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.lock_shield, size: 12, color: idMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: idMuted, fontSize: 10.5),
          ),
        ),
      ],
    );
  }
}
