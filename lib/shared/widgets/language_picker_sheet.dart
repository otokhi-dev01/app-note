import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';

/// Language picker, iOS-26 style: the control that opens it morphs into a
/// glass pull-down anchored where it was, matching [NoteAttachmentPopup] and
/// the other menus — rather than raising a bottom sheet.
///
/// Picking a language persists it via [LanguagePreferences.setLanguage],
/// which also fires the app-wide [Get.updateLocale] rebuild; the menu closes
/// itself on selection.
class LanguagePickerMenu extends StatelessWidget {
  /// Builds the control the menu grows out of, given the callback that opens
  /// it. A builder rather than a plain widget, since both call sites bring
  /// their own tap handling (a glass button, a settings row) that
  /// `GlassMenu.trigger`'s own [GestureDetector] would compete with.
  final Widget Function(BuildContext context, VoidCallback toggleMenu)
  triggerBuilder;

  /// Where the menu attaches. The flag button sits in a top-right app bar and
  /// wants to open downward; the Settings row sits mid-screen and is left to
  /// auto-detect.
  final lg.GlassMenuAlignment? menuAlignment;

  /// Set on a trigger much wider than the menu — a full-width settings row —
  /// so the body blooms from a point instead of from a glass blob the width
  /// of the row.
  final bool morphFromZero;

  const LanguagePickerMenu({
    super.key,
    required this.triggerBuilder,
    this.menuAlignment,
    this.morphFromZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = LanguagePreferences();
    final current = prefs.language;

    return lg.GlassMenu(
      triggerBuilder: triggerBuilder,
      menuWidth: 250,
      menuAlignment: menuAlignment,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      morphFromZero: morphFromZero,
      items: [
        for (final language in AppLanguage.values)
          lg.GlassMenuItem(
            title: language.label,
            icon: Text(language.flag, style: const TextStyle(fontSize: 20)),
            // The checkmark is what the old sheet used to mark the active
            // language; keeping it means the menu still answers "which one am
            // I on?" without having to close it again.
            trailing: language == current
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: IosSemanticColors.blue,
                    size: 20,
                  )
                : null,
            onTap: () => prefs.setLanguage(language),
          ),
      ],
    );
  }
}
