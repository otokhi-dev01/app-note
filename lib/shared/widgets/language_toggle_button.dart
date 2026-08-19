import 'package:flutter/material.dart';

import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_picker_sheet.dart';

/// A flag button showing the current language. Tapping it opens the glass
/// language picker popup (same one used from Settings) rather than toggling
/// straight to the other language.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final current = LanguagePreferences().language;

    return CustomGlassButton(
      onPressed: () => showLanguagePickerSheet(context),
      semanticLabel: 'Change language',
      width: 44,
      height: 44,
      shape: GlassShape.circle,
      blur: 10,
      opacity: 0.15,
      thickness: 8,
      padding: EdgeInsets.zero,
      child: Text(current.flag, style: const TextStyle(fontSize: 20)),
    );
  }
}
