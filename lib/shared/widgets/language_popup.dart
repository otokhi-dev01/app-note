import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';

/// An anchored language picker matching the Note Detail more-options popup.
class LanguagePopup extends StatelessWidget {
  final Widget Function(BuildContext context, VoidCallback toggleMenu)
  triggerBuilder;

  const LanguagePopup({super.key, required this.triggerBuilder});

  @override
  Widget build(BuildContext context) {
    final current = LanguagePreferences().language;

    return lg.GlassMenu(
      triggerBuilder: triggerBuilder,
      menuWidth: 250,
      menuAlignment: lg.GlassMenuAlignment.topRight,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      items: [
        for (final language in AppLanguage.values)
          lg.GlassMenuItem(
            title: language.label,
            icon: Text(language.flag, style: const TextStyle(fontSize: 22)),
            trailing: current == language
                ? const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: IosSemanticColors.blue,
                    size: 20,
                  )
                : null,
            isSelected: current == language,
            onTap: () => LanguagePreferences().setLanguage(language),
          ),
      ],
    );
  }
}
