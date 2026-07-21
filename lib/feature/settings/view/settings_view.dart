import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../presentation/controllers/settings_controller.dart';
import '../presentation/widgets/languages_selector_widget.dart';
import '../presentation/widgets/settings_intro_card_widget.dart';
import '../presentation/widgets/settings_section_card_widget.dart';
import '../presentation/widgets/theme_mode_selector_widget.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color pageColor = theme.scaffoldBackgroundColor;

    return ColoredBox(
      color: pageColor,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            automaticallyImplyLeading: false,
            stretch: true,
            border: null,
            backgroundColor: pageColor.withValues(alpha: 0.94),
            largeTitle: Text(
              'settings'.tr,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsIntroCardWidget(title: 'app_settings'.tr),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            sliver: SliverList.list(
              children: <Widget>[
                SettingsSectionCardWidget(
                  icon: CupertinoIcons.circle_lefthalf_fill,
                  title: 'appearance'.tr,
                  subtitle: 'appearance_description'.tr,
                  child: const ThemeModeSelector(),
                ),
                const SizedBox(height: 12),
                SettingsSectionCardWidget(
                  icon: CupertinoIcons.globe,
                  title: 'language'.tr,
                  subtitle: 'language_description'.tr,
                  child: const LanguageSelector(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
