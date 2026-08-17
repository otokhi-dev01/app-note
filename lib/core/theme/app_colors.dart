import 'package:flutter/material.dart';

import 'package:Note/core/theme/app_theme.dart';

/// Semantic color roles, resolved once per theme.
///
/// Screens ask for the *role* (`colors.secondaryText`) instead of hard-coding
/// `Colors.white70` / `Colors.black54`, so light and dark stay in step and a
/// palette change happens in one place.
///
/// ```dart
/// final colors = AppColors.of(context);
/// Text('Hi', style: TextStyle(color: colors.primaryText));
/// ```
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Page background beneath any glass layer.
  final Color background;

  /// Card/panel tint — reads as a white card in light, subtle glass in dark.
  final Color panelTint;

  final Color primaryText;
  final Color secondaryText;
  final Color placeholder;

  /// Chrome glyphs: close buttons, clear-field icons, row chevrons.
  final Color mutedIcon;

  /// Unselected chip/cell fill and its glyph.
  final Color cellFill;
  final Color cellIcon;

  /// Hairlines and separators.
  final Color divider;

  const AppColors({
    required this.background,
    required this.panelTint,
    required this.primaryText,
    required this.secondaryText,
    required this.placeholder,
    required this.mutedIcon,
    required this.cellFill,
    required this.cellIcon,
    required this.divider,
  });

  static final AppColors light = AppColors(
    background: AppTheme.bodyColor,
    // Translucent card white: panels stay legible against the light scaffold,
    // which a plain white glass tint would disappear into.
    panelTint: AppTheme.cardColor.withValues(alpha: 0.55),
    primaryText: AppTheme.textPrimary,
    secondaryText: AppTheme.textGrey,
    placeholder: AppTheme.hintColor,
    mutedIcon: AppTheme.textGrey,
    cellFill: AppTheme.dividerColor,
    cellIcon: AppTheme.textSecondary,
    divider: AppTheme.dividerColor,
  );

  static final AppColors dark = AppColors(
    background: AppTheme.darkBackground,
    // Matches the white-at-0.1 tint the shared glass widgets default to.
    panelTint: Colors.white.withValues(alpha: 0.08),
    primaryText: AppTheme.darkTextPrimary,
    secondaryText: AppTheme.darkTextSecondary,
    placeholder: AppTheme.darkTextSecondary.withValues(alpha: 0.7),
    mutedIcon: AppTheme.darkTextSecondary,
    cellFill: AppTheme.darkDividerColor,
    cellIcon: AppTheme.darkTextPrimary,
    divider: AppTheme.darkDividerColor,
  );

  /// The palette for the current theme.
  ///
  /// Falls back to the brightness-appropriate defaults if the extension was
  /// never registered, so a widget can never crash on a null lookup.
  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Glyph color that stays legible on top of an accent swatch.
  ///
  /// The threshold sits high on purpose: white is the intended look on the
  /// saturated swatches (pink, red, blue, purple), and only the pale yellows
  /// `#FFB703` / `#FFCC00` are bright enough that a white glyph disappears.
  /// `ThemeData.estimateBrightnessForColor` cuts at 0.15 and would flip most of
  /// the palette to black.
  static Color onAccent(Color accent) =>
      accent.computeLuminance() > 0.5 ? AppTheme.textPrimary : Colors.white;

  @override
  AppColors copyWith({
    Color? background,
    Color? panelTint,
    Color? primaryText,
    Color? secondaryText,
    Color? placeholder,
    Color? mutedIcon,
    Color? cellFill,
    Color? cellIcon,
    Color? divider,
  }) => AppColors(
    background: background ?? this.background,
    panelTint: panelTint ?? this.panelTint,
    primaryText: primaryText ?? this.primaryText,
    secondaryText: secondaryText ?? this.secondaryText,
    placeholder: placeholder ?? this.placeholder,
    mutedIcon: mutedIcon ?? this.mutedIcon,
    cellFill: cellFill ?? this.cellFill,
    cellIcon: cellIcon ?? this.cellIcon,
    divider: divider ?? this.divider,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      panelTint: Color.lerp(panelTint, other.panelTint, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      placeholder: Color.lerp(placeholder, other.placeholder, t)!,
      mutedIcon: Color.lerp(mutedIcon, other.mutedIcon, t)!,
      cellFill: Color.lerp(cellFill, other.cellFill, t)!,
      cellIcon: Color.lerp(cellIcon, other.cellIcon, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
