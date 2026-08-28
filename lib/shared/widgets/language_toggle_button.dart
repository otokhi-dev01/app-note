import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// A flag button showing the current language and opening its settings page.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final current = LanguagePreferences().language;

    return CustomGlassButton(
      onPressed: () => Get.toNamed(Routes.LANGUAGE),
      semanticLabel: 'language_title'.tr,
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
