import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class LanguageSelector
    extends GetView<SettingsController> {
  const LanguageSelector({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Column(
        children: <Widget>[
          _LanguageOptionTile(
            title: 'english'.tr,
            description:
            'english_description'.tr,
            flagAsset:
            'assets/images/flags/usa.png',
            fallbackFlag: '🇺🇸',
            value: AppLanguage.english,
            selectedValue:
            controller.selectedLanguage.value,
            onChanged:
            controller.changeLanguage,
          ),
          const SizedBox(height: 10),
          _LanguageOptionTile(
            title: 'khmer'.tr,
            description:
            'khmer_description'.tr,
            flagAsset:
            'assets/images/flags/cambodia.png',
            fallbackFlag: '🇰🇭',
            value: AppLanguage.khmer,
            selectedValue:
            controller.selectedLanguage.value,
            onChanged:
            controller.changeLanguage,
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionTile
    extends StatelessWidget {
  final String title;
  final String description;
  final String flagAsset;
  final String fallbackFlag;
  final AppLanguage value;
  final AppLanguage selectedValue;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguageOptionTile({
    required this.title,
    required this.description,
    required this.flagAsset,
    required this.fallbackFlag,
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
              _FlagLogo(
                assetPath: flagAsset,
                fallbackFlag: fallbackFlag,
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

class _FlagLogo extends StatelessWidget {
  final String assetPath;
  final String fallbackFlag;

  const _FlagLogo({
    required this.assetPath,
    required this.fallbackFlag,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        border: Border.all(
          color:
          colorScheme.outlineVariant.withValues(
            alpha: 0.35,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
              ) {
            return Center(
              child: Text(
                fallbackFlag,
                style: const TextStyle(
                  fontSize: 27,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}