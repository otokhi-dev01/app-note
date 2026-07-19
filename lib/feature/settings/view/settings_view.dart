import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/main/presentation/widgets/app_liquid_background_widget.dart';
import 'package:note_app/feature/main/presentation/widgets/main_tab_header_widget.dart';
import '../presentation/controllers/settings_controller.dart';
import '../presentation/widgets/languages_selector_widget.dart';
import '../presentation/widgets/settings_section_card_widget.dart';
import '../presentation/widgets/theme_mode_selector_widget.dart';

class SettingsView
    extends GetView<SettingsController> {
  const SettingsView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: AppLiquidBackgroundWidget(),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  0,
                ),
                child: MainTabHeaderWidget(
                  title: 'settings'.tr,
                  subtitle: 'app_settings'.tr,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  physics:
                  const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    120,
                  ),
                  children: <Widget>[
                    SettingsSectionCardWidget(
                      title: 'appearance'.tr,
                      subtitle:
                      'appearance_description'.tr,
                      child:
                      const ThemeModeSelector(),
                    ),
                    const SizedBox(height: 14),
                    SettingsSectionCardWidget(
                      title: 'language'.tr,
                      subtitle:
                      'language_description'.tr,
                      child:
                      const LanguageSelector(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}