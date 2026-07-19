import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class ThemeModeSelector
    extends GetView<SettingsController> {
  const ThemeModeSelector({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Column(
        children: <Widget>[
          _ThemeOptionTile(
            icon: CupertinoIcons.device_phone_portrait,
            title: 'system_default'.tr,
            description:
            'system_default_description'.tr,
            value: ThemeMode.system,
            selectedValue:
            controller.selectedThemeMode.value,
            onChanged:
            controller.changeThemeMode,
          ),
          const SizedBox(height: 10),
          _ThemeOptionTile(
            icon: CupertinoIcons.sun_max,
            title: 'light_mode'.tr,
            description:
            'light_mode_description'.tr,
            value: ThemeMode.light,
            selectedValue:
            controller.selectedThemeMode.value,
            onChanged:
            controller.changeThemeMode,
          ),
          const SizedBox(height: 10),
          _ThemeOptionTile(
            icon: CupertinoIcons.moon_stars,
            title: 'dark_mode'.tr,
            description:
            'dark_mode_description'.tr,
            value: ThemeMode.dark,
            selectedValue:
            controller.selectedThemeMode.value,
            onChanged:
            controller.changeThemeMode,
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ThemeMode value;
  final ThemeMode selectedValue;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool selected =
        value == selectedValue;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(
        alpha: 0.11,
      )
          : colorScheme.surface.withValues(
        alpha: 0.50,
      ),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          onChanged(value);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration:
          const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(
                alpha: 0.55,
              )
                  : colorScheme.outlineVariant
                  .withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                  colorScheme.primary.withValues(
                    alpha: selected ? 0.16 : 0.09,
                  ),
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme
                          .textTheme.titleSmall
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: theme
                          .textTheme.bodySmall
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration:
                const Duration(milliseconds: 180),
                child: selected
                    ? Icon(
                  CupertinoIcons
                      .checkmark_circle_fill,
                  key: const ValueKey<bool>(
                    true,
                  ),
                  size: 23,
                  color: colorScheme.primary,
                )
                    : Icon(
                  CupertinoIcons.circle,
                  key: const ValueKey<bool>(
                    false,
                  ),
                  size: 23,
                  color: colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}