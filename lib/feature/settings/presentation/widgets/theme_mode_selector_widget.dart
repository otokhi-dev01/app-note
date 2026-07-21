import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import 'settings_selection_tile_widget.dart';

class ThemeModeSelector extends GetView<SettingsController> {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: <Widget>[
          _buildOption(
            context: context,
            icon: CupertinoIcons.device_phone_portrait,
            title: 'system_default'.tr,
            description: 'system_default_description'.tr,
            value: ThemeMode.system,
          ),
          const SizedBox(height: 10),
          _buildOption(
            context: context,
            icon: CupertinoIcons.sun_max,
            title: 'light_mode'.tr,
            description: 'light_mode_description'.tr,
            value: ThemeMode.light,
          ),
          const SizedBox(height: 10),
          _buildOption(
            context: context,
            icon: CupertinoIcons.moon_stars,
            title: 'dark_mode'.tr,
            description: 'dark_mode_description'.tr,
            value: ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required ThemeMode value,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool selected = controller.selectedThemeMode.value == value;

    return SettingsSelectionTileWidget(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: selected ? 0.16 : 0.09),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, size: 22, color: colors.primary),
      ),
      title: title,
      description: description,
      selected: selected,
      onTap: () {
        controller.changeThemeMode(value);
      },
    );
  }
}
