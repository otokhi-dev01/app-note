import 'package:flutter/material.dart';
import 'package:Note/core/theme/app_theme.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color panelTint;
  final Color primaryText;
  final Color secondaryText;
  final Color placeholder;
  final Color mutedIcon;
  final Color cellFill;
  final Color cellIcon;
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
    panelTint: Colors.white.withValues(alpha: 0.08),
    primaryText: AppTheme.darkTextPrimary,
    secondaryText: AppTheme.darkTextSecondary,
    placeholder: AppTheme.darkTextSecondary.withValues(alpha: 0.7),
    mutedIcon: AppTheme.darkTextSecondary,
    cellFill: AppTheme.darkDividerColor,
    cellIcon: AppTheme.darkTextPrimary,
    divider: AppTheme.darkDividerColor,
  );

  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
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
