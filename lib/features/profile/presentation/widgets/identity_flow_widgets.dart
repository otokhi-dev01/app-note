import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/feedback/app_snackbar.dart';

import 'package:Note/shared/widgets/glass_widgets.dart';

// Palette for the Digital Civic ID flow.
const idInk = Color(0xFF1C1C1E);
const idNavy = Color(0xFF2C2C2E);
const idNavyLight = Color(0xFF3A3A3C);
const idAccent = Color(0xFF007AFF);
const idGreen = Color(0xFF34C759);
const idAmber = Color(0xFFFF9500);
const idMuted = Color(0xFF8E8E93);
const idBorder = Color(0xFFD1D1D6);

const idScreenBg = Color(0xFFF2F2F7);

/// The persistent bilingual brand header shown at the top of every screen in
/// the identity scan flow.
class IdentityAppHeader extends StatelessWidget {
  const IdentityAppHeader({super.key, this.onBackTap, this.onCameraTap});

  final VoidCallback? onBackTap;
  final VoidCallback? onCameraTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              CustomGlassButton(
                onPressed: onBackTap,
                width: 44,
                height: 44,
                shape: GlassShape.circle,
                blur: 10,
                opacity: 0.1,
                thickness: 8,
                padding: EdgeInsets.zero,
                child: Icon(
                  CupertinoIcons.chevron_left,
                  color: theme.colorScheme.onSurface,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'identity_app_title'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              if (onCameraTap != null)
                CustomGlassButton(
                  onPressed: onCameraTap,
                  width: 44,
                  height: 44,
                  shape: GlassShape.circle,
                  blur: 10,
                  opacity: 0.1,
                  thickness: 8,
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.camera_fill,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


/// The success/pending banner.
class IdentityStatusBanner extends StatelessWidget {
  const IdentityStatusBanner({super.key, required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = verified ? idGreen : theme.colorScheme.onSurfaceVariant;
    
    return CustomGlassContainer(
      borderRadius: 16,
      blur: 20,
      opacity: 0.08,
      thickness: 8,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              verified
                  ? CupertinoIcons.checkmark_shield_fill
                  : CupertinoIcons.doc_text_viewfinder,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'identity_pending_title'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'identity_pending_subtitle'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (verified)
            IdentityTag(
              'identity_sealed_badge'.tr,
              color: idGreen,
              icon: CupertinoIcons.lock_fill,
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (trailing != null) Flexible(child: trailing!),
      ],
    );
  }
}

/// A small colored pill used for status tags.
class IdentityTag extends StatelessWidget {
  const IdentityTag(this.label, {super.key, this.color = idAccent, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A bordered card wrapping one OCR'd field.
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
    final theme = Theme.of(context);
    return CustomGlassContainer(
      width: double.infinity,
      borderRadius: 16,
      blur: 20,
      opacity: 0.05,
      thickness: 8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (tag != null) tag!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}


/// The National ID Number field's value.
class IdentityCopyableValue extends StatelessWidget {
  const IdentityCopyableValue(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontFamily: 'monospace',
            ),
          ),
        ),
        CustomGlassButton(
          onPressed: () {
            unawaited(Clipboard.setData(ClipboardData(text: value)));
            AppSnackbar.success(
              'identity_copied_title'.tr,
              'identity_copied_message'.tr,
            );
          },
          width: 80,
          height: 36,
          borderRadius: 12,
          opacity: 0.1,
          thickness: 4,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.doc_on_doc, size: 14),
              const SizedBox(width: 6),
              Text(
                'identity_copy_action'.tr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
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
    this.onScan,
    this.onView,
    this.onDownload,
  });

  final String label;
  final String? imagePath;
  final bool front;
  final VoidCallback? onScan;
  final VoidCallback? onView;
  final VoidCallback? onDownload;

  bool get _hasImage =>
      imagePath != null &&
      imagePath!.isNotEmpty &&
      File(imagePath!).existsSync();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final side = front ? 'front' : 'back';
    final scanLabel = (front ? 'identity_scan_front' : 'identity_scan_back').tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.586,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Material(
                  color: _hasImage
                      ? theme.colorScheme.surface
                      : (isDark ? idNavy : idScreenBg),
                  child: InkWell(
                    onTap: _hasImage ? onView : onScan,
                    child: _hasImage
                        ? Image.file(File(imagePath!), fit: BoxFit.cover)
                        : _placeholderMock(context),
                  ),
                ),
                if (_hasImage && (onView != null || onDownload != null))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onView != null)
                          _smallActionButton(
                            icon: CupertinoIcons.arrow_up_left_arrow_down_right,
                            onTap: onView,
                          ),
                        if (onView != null && onDownload != null)
                          const SizedBox(width: 6),
                        if (onDownload != null)
                          _smallActionButton(
                            icon: CupertinoIcons.arrow_down_to_line,
                            onTap: onDownload,
                          ),
                      ],
                    ),
                  ),
                if (!_hasImage)
                   Center(
                     child: CustomGlassButton(
                       onPressed: onScan,
                       width: 44,
                       height: 44,
                       shape: GlassShape.circle,
                       opacity: 0.2,
                       padding: EdgeInsets.zero,
                       child: const Icon(CupertinoIcons.camera_fill, size: 20, color: Colors.white),
                     ),
                   ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _smallActionButton({required IconData icon, VoidCallback? onTap}) {
    return CustomGlassButton(
      onPressed: onTap,
      width: 32,
      height: 32,
      borderRadius: 8,
      opacity: 0.3,
      thickness: 4,
      padding: EdgeInsets.zero,
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }

  Widget _placeholderMock(BuildContext context) {
    final theme = Theme.of(context);
    final color = front ? idGreen : theme.colorScheme.primary;
    return Opacity(
      opacity: 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(front ? CupertinoIcons.person_crop_rectangle : CupertinoIcons.barcode_viewfinder, 
               size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            (front ? 'identity_side_front' : 'identity_side_back').tr.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// The encrypted MRZ / chip-signature block.
class IdentityMrzBlock extends StatelessWidget {
  const IdentityMrzBlock({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomGlassContainer(
      width: double.infinity,
      borderRadius: 16,
      blur: 30,
      opacity: 0.1,
      thickness: 10,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.lock_shield_fill,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'identity_mrz_title'.tr.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const IdentityTag('E2EE-AES'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              lines.join('\n'),
              style: const TextStyle(
                color: Color(0xFF7FE0B8),
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 0.8,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// High-end primary action button.
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
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Destructive secondary action.
class IdentityDestructiveButton extends StatelessWidget {
  const IdentityDestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = CupertinoIcons.trash,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF3B30),
          side: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Closing footer caption.
class IdentityFooterNote extends StatelessWidget {
  const IdentityFooterNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.lock_shield, size: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

