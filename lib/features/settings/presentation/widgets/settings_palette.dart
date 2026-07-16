import 'package:flutter/material.dart';

/// Theme-derived colors used by the settings feature.
///
/// Keeping these values close to [ColorScheme] lets the grouped iOS treatment
/// follow both the app theme and the user's selected appearance.
@immutable
final class SettingsPalette {
  const SettingsPalette._({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.onAccent,
    required this.destructive,
    required this.separator,
    required this.cardBorder,
    required this.pressedOverlay,
    required this.cardShadows,
  });

  factory SettingsPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SettingsPalette._(
      isDark: isDark,
      background: theme.scaffoldBackgroundColor,
      surface: colors.surface,
      primaryText: colors.onSurface,
      secondaryText: colors.onSurfaceVariant,
      accent: colors.primary,
      onAccent: colors.onPrimary,
      destructive: colors.error,
      separator: colors.outlineVariant.withValues(alpha: isDark ? .62 : .72),
      cardBorder: colors.outlineVariant.withValues(alpha: isDark ? .42 : .52),
      pressedOverlay: colors.primary.withValues(alpha: isDark ? .12 : .08),
      cardShadows: isDark
          ? const <BoxShadow>[]
          : <BoxShadow>[
              BoxShadow(
                color: colors.shadow.withValues(alpha: .045),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
    );
  }

  final bool isDark;
  final Color background;
  final Color surface;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color onAccent;
  final Color destructive;
  final Color separator;
  final Color cardBorder;
  final Color pressedOverlay;
  final List<BoxShadow> cardShadows;

  Color tinted(Color color, {double? opacity}) {
    return color.withValues(alpha: opacity ?? (isDark ? .20 : .12));
  }
}
