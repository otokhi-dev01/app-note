import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// Glass bottom-sheet popup for choosing English or Khmer. Selecting a
/// language persists it via [LanguagePreferences.setLanguage] (which also
/// triggers the app-wide [Get.updateLocale] rebuild) and closes the sheet.
Future<void> showLanguagePickerSheet(BuildContext context) {
  final prefs = LanguagePreferences();
  return CustomGlassSheet.show<void>(
    context: context,
    isScrollable: false,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) {
        final current = prefs.language;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'language_title'.tr,
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < AppLanguage.values.length; i++) ...[
                _buildOption(
                  sheetContext,
                  language: AppLanguage.values[i],
                  selected: AppLanguage.values[i] == current,
                  onSelect: () {
                    prefs.setLanguage(AppLanguage.values[i]);
                    setState(() {});
                    Navigator.of(sheetContext).pop();
                  },
                ),
                if (i < AppLanguage.values.length - 1)
                  const Divider(indent: 56, height: 1),
              ],
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildOption(
  BuildContext context, {
  required AppLanguage language,
  required bool selected,
  required VoidCallback onSelect,
}) {
  return CustomGlassListTile(
    onTap: onSelect,
    leading: Text(language.flag, style: const TextStyle(fontSize: 24)),
    title: Text(
      language.label,
      style: TextStyle(
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
      ),
    ),
    trailing: selected
        ? const Icon(Icons.check_circle_rounded, color: AppTheme.folderPink)
        : null,
  );
}
