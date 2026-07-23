import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import 'settings_flag_widget.dart';
import 'settings_selection_tile_widget.dart';

class LanguageSelector extends GetView<SettingsController> {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: <Widget>[
          SettingsSelectionTileWidget(
            leading: SettingsFlagWidget(
              assetPath: 'assets/images/flags/usa.png',
              fallbackFlag: '🇺🇸',
            ),
            title: 'english'.tr,
            description: 'english_description'.tr,
            selected: controller.selectedLanguage.value == AppLanguage.english,
            onTap: () {
              controller.changeLanguage(AppLanguage.english);
            },
          ),
          SizedBox(height: 10),
          SettingsSelectionTileWidget(
            leading: SettingsFlagWidget(
              assetPath: 'assets/images/flags/cambodia.png',
              fallbackFlag: '🇰🇭',
            ),
            title: 'khmer'.tr,
            description: 'khmer_description'.tr,
            selected: controller.selectedLanguage.value == AppLanguage.khmer,
            onTap: () {
              controller.changeLanguage(AppLanguage.khmer);
            },
          ),
        ],
      ),
    );
  }
}
