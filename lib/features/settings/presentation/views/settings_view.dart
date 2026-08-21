import 'dart:async';

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/core/storage/theme_storage.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_picker_sheet.dart';

/// The front door for app-wide settings, reached from the gear button on the
/// Folders screen. Every row here is either real, working functionality or
/// nothing at all: no fake subscription, storage quota, password change, or
/// two-factor auth, since none of that exists in this app.
///
/// Restyled for iOS 26's Liquid Glass language: concentric-radius cards,
/// glossy gradient icon badges with a colour-matched glow, a soft halo
/// behind the avatar, section footnotes and an about-style footer the way
/// Apple's own Settings app closes a group, and [_SettingsPressable] rows
/// that dim on press instead of showing a Material ripple.
///
/// Profile editing (avatar/name) used to be its own screen reached via a
/// "Personal Information" row; it's folded directly into the identity block
/// here instead, so [ProfileController] is bound to this route too.
class SettingsView extends GetView<ProfileController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIdentity(context),
                    const SizedBox(height: 28),
                    _buildSectionLabel(context, "section_preferences".tr),
                    const SizedBox(height: 10),
                    _buildCard(context, [
                      _buildDarkModeRow(context),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.paintbrush_fill,
                        tint: _SettingsTint.appearance,
                        title: "appearance_title".tr,
                        onTap: () => Get.toNamed(Routes.APPEARANCE),
                      ),
                      _buildRow(
                        context,
                        icon: CupertinoIcons.list_bullet,
                        tint: _SettingsTint.notePreferences,
                        title: "note_preferences_title".tr,
                        onTap: () => Get.toNamed(Routes.NOTE_PREFERENCES),
                      ),
                      // The row itself is the menu's trigger, so it morphs
                      // into the pull-down in place. `morphFromZero` because
                      // the row is far wider than the menu — without it the
                      // body would spawn as a glass blob the width of the
                      // whole card.
                      LanguagePickerMenu(
                        morphFromZero: true,
                        triggerBuilder: (context, toggleMenu) => _buildRow(
                          context,
                          icon: CupertinoIcons.globe,
                          tint: _SettingsTint.language,
                          title: "language_title".tr,
                          trailingText: LanguagePreferences().language.label,
                          onTap: toggleMenu,
                        ),
                      ),
                    ]),
                    _buildSectionFooter(
                      context,
                      "section_preferences_footer".tr,
                    ),
                    const SizedBox(height: 28),
                    _buildSectionLabel(context, "section_support".tr),
                    const SizedBox(height: 10),
                    _buildCard(context, [
                      _buildRow(
                        context,
                        icon: CupertinoIcons.question_circle_fill,
                        tint: _SettingsTint.helpCenter,
                        title: "help_center_title".tr,
                        onTap: () => Get.toNamed(Routes.HELP_CENTER),
                      ),
                    ]),
                    _buildSectionFooter(context, "section_support_footer".tr),
                    const SizedBox(height: 34),
                    _buildAccountAction(context),
                    const SizedBox(height: 24),
                    _buildVersionFooter(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return CustomGlassSliverAppBar(
      expandedHeight: 140,
      toolbarHeight: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      centerTitle: true,
      leading: CustomGlassButton(
        onPressed: () => Get.back(),
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        padding: EdgeInsets.zero,
        child: Icon(
          CupertinoIcons.chevron_left,
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
      ),
      title: Text(
        "settings_title".tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 5),
      largeTitle: Text(
        "settings_title".tr,
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 34,
        ),
      ),
    );
  }

  /// The account card at the top of the screen: avatar, name, and whatever
  /// identifies the account below it.
  ///
  /// Laid out as a row inside the same glass card as the settings groups
  /// rather than as a centred portrait — it reads as the first item of the
  /// list that way, which is where an account belongs on this screen. Both
  /// edit affordances survive the move: the camera badge still changes the
  /// photo, and the name is still tappable to rename. The soft tinted halo
  /// behind the avatar is the one "hero" flourish this row allows itself.
  Widget _buildIdentity(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final isGuest = controller.isGuestMode.value;
      final imagePath = controller.userImagePath.value;
      final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();
      final subtitle = controller.userPhone.value;

      return _buildCard(context, [
        _SettingsPressable(
          onTap: () => Get.toNamed(Routes.PROFILE),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.55),
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: hasImage
                            ? FileImage(File(imagePath))
                            : null,
                        child: hasImage
                            ? null
                            : Icon(
                                CupertinoIcons.person_fill,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 32,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              controller.userName.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          if (!isGuest) ...[
                            const SizedBox(width: 6),
                            Icon(
                              CupertinoIcons.chevron_forward,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]);
    });
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        // Grouped-list headers are a quiet label above the card, not a
        // heading in their own right — the card underneath carries the
        // weight, so this steps back to muted uppercase.
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          fontSize: 12,
        ),
      ),
    );
  }

  /// A quiet footnote under a settings group, the way Apple's own Settings
  /// app explains what a section does rather than leaving the row titles to
  /// speak for themselves.
  Widget _buildSectionFooter(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 12, top: 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> rows) {
    final theme = Theme.of(context);
    return CustomGlassContainer(
      borderRadius: 24,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.zero,
      showGlow: true,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(
                height: 1,
                // 16 padding + 30 badge + 12 gap: the rule starts where the
                // labels do, the way a grouped iOS list separates its rows.
                indent: 58,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required Color tint,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return _SettingsPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconBadge(icon: icon, tint: tint),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// A real, working quick toggle: on switches to explicit dark mode, off to
  /// explicit light mode. The full System/Light/Dark picker (which this
  /// can't represent as a single switch) is still available via the
  /// "Appearance" row below it.
  Widget _buildDarkModeRow(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const _IconBadge(
            icon: CupertinoIcons.moon_fill,
            tint: _SettingsTint.darkMode,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text("dark_mode".tr, style: theme.textTheme.bodyLarge),
          ),
          Switch.adaptive(
            value: isDark,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ThemeStorage().switchTheme(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountAction(BuildContext context) {
    final guestMode = Get.find<GuestModeService>();

    return Obx(() {
      final isGuest = guestMode.isGuestMode.value;
      return CustomGlassButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          if (isGuest) {
            _goToLogin();
          } else {
            unawaited(_logout());
          }
        },
        semanticLabel: isGuest ? "log_in_create_account".tr : "log_out".tr,
        width: double.infinity,
        borderRadius: 24,
        foregroundColor: isGuest ? AppTheme.folderPink : Colors.red,
        glassColor: (isGuest ? AppTheme.folderPink : Colors.red).withValues(
          alpha: 0.12,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isGuest
                  ? CupertinoIcons.arrow_right_circle
                  : CupertinoIcons.square_arrow_right,
              color: isGuest ? AppTheme.folderPink : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              isGuest ? "log_in_create_account".tr : "log_out".tr,
              style: TextStyle(
                color: isGuest ? AppTheme.folderPink : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// The quiet app-identity footer real Settings screens close on: no
  /// action, just a reminder of what you're inside. "Piisiit Note" and the
  /// version number are placeholders — wire them up to `package_info_plus`
  /// when you're ready, or delete this call in `build` if you'd rather skip
  /// it entirely.
  Widget _buildVersionFooter(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
    );
    final versionLabel = "version_label".tr;
    return Center(
      child: Column(
        children: [
          Text(
            "Pii Note",
            style: mutedStyle?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text("$versionLabel 1.0.0", style: mutedStyle),
        ],
      ),
    );
  }

  void _goToLogin() => Get.offAllNamed(Routes.LOGIN);

  Future<void> _logout() async {
    await Get.find<Logout>()(const NoParams());
    unawaited(Get.offAllNamed(Routes.ONBOARDING));
  }
}

/// A settings-row tap target with an iOS-flavoured press state — a soft dim
/// rather than a Material ripple — plus a light haptic tick so rows feel
/// native instead of borrowed from Android.
class _SettingsPressable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _SettingsPressable({required this.onTap, required this.child});

  @override
  State<_SettingsPressable> createState() => _SettingsPressableState();
}

class _SettingsPressableState extends State<_SettingsPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          color: _pressed
              ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
              : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

/// The tinted square behind a settings row's glyph.
///
/// The colour is what tells the rows apart at a glance in a grouped list —
/// the icons themselves are small and similarly weighted, so a reader scans
/// for "the green one" long before they read the label. Iced with a top-lit
/// gradient, a hairline glass edge, and a soft colour-matched glow so the
/// badges read as glossy little app icons rather than flat tiles.
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const _IconBadge({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(tint, Colors.white, 0.2)!, tint],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // White on every tint rather than a per-badge foreground: these squares
      // are saturated enough that white is the legible choice on all of them,
      // and a single rule keeps a new row from having to pick a pair.
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}

/// Row badge colours.
///
/// Deliberately not pulled from the theme's palette: this screen's rows want
/// to be told apart from each other, which a single seeded scheme can't do.
/// They hold in both light and dark, so they are not re-declared per theme.
abstract final class _SettingsTint {
  static const darkMode = Color(0xFF5E5CE6);
  static const appearance = Color(0xFFFF9F0A);
  static const notePreferences = Color(0xFF32ADE6);
  static const language = Color(0xFF30D158);
  static const helpCenter = Color(0xFF8E8E93);
}
