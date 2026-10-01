import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:Note/features/auth/presentation/controllers/account_input_controller.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class AccountInputField extends StatelessWidget {
  const AccountInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
  });

  final AccountInputController controller;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  Future<void> _pickCountry(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final searchBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      );

      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Theme(
          data: theme.copyWith(
            dialogTheme: theme.dialogTheme.copyWith(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: colors.onSurface.withValues(alpha: 0.08),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              surfaceTintColor: Colors.transparent,
            ),
            listTileTheme: ListTileThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minVerticalPadding: 14,
            ),
          ),
          child: CountryPickerDialog(
            searchText: 'search_country'.tr,
            languageCode: Get.locale?.languageCode ?? 'en',
            countryList: countries,
            filteredCountries: countries,
            selectedCountry: controller.country,
            onCountryChanged: controller.selectCountry,
            style: PickerDialogStyle(
              width: 400,
              padding: const EdgeInsets.all(16),
              backgroundColor: colors.surface,
              countryNameStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
              countryCodeStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
              listTilePadding: const EdgeInsets.symmetric(horizontal: 12),
              listTileDivider: Divider(
                height: 1,
                thickness: 0.5,
                indent: 52,
                endIndent: 12,
                color: colors.onSurface.withValues(alpha: 0.08),
              ),
              searchFieldCursorColor: colors.primary,
              searchFieldInputDecoration: InputDecoration(
                hintText: 'search_country'.tr,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  size: 20,
                  color: colors.primary,
                ),
                filled: true,
                fillColor: colors.onSurface.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: searchBorder,
                enabledBorder: searchBorder,
                focusedBorder: searchBorder.copyWith(
                  borderSide: BorderSide(
                    color: colors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isPhone = controller.isPhoneInput;
        final country = controller.country;
        return Row(
          children: [
            // Keep the text field in the same position in the widget tree so
            // switching modes preserves its focus, selection, and keyboard.
            if (isPhone)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomGlassButton(
                  key: const ValueKey('account-country-picker'),
                  onPressed: enabled ? () => _pickCountry(context) : null,
                  semanticLabel:
                      '${'country_code'.tr}: ${country.localizedName(Get.locale?.languageCode ?? 'en')}, +${country.fullCountryCode}',
                  height: 56,
                  minHeight: 56,
                  borderRadius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: theme.colorScheme.onSurface,
                  glowColor: theme.colorScheme.primary,
                  textStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(country.flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Text('+${country.fullCountryCode}'),
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            Expanded(
              child: CustomGlassTextField(
                controller: controller,
                enabled: enabled,
                placeholder: isPhone
                    ? 'phone_number_hint'.tr
                    : 'username_email_phone_hint'.tr,
                height: 56,
                borderRadius: 18,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                onChanged: onChanged,
                prefixIcon: isPhone
                    ? null
                    : Icon(
                        CupertinoIcons.person_fill,
                        size: 20,
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                      ),
                textStyle: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                placeholderStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
