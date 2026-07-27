# Implementation Plan - Multi-language Support (English, Khmer, Chinese)

This plan adds language localization support to the app using GetX Translations, focusing initially on the Login and Register screens.

## Proposed Changes

### [Core]

#### [NEW] [app_translations.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/app/translations/app_translations.dart)
- Create a class implementing `Translations`.
- Add dictionary maps for:
    - **English (en_US)**
    - **Khmer (km_KH)**
    - **Chinese (zh_CN)**
- Include keys for all text on Login and Register screens.

#### [MODIFY] [main.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/app/main.dart)
- Configure `GetMaterialApp` with:
    - `translations: AppTranslations()`
    - `locale: Get.deviceLocale` (or a saved preference)
    - `fallbackLocale: const Locale('en', 'US')`

### [UI Components]

#### [NEW] [language_picker_button.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/core/widgets/language_picker_button.dart)
- Create a modern, floating language selector button.
- Uses `LiquidGlassContainer` to match the app's aesthetic.
- Opens a simple dialog or sheet to switch between the three supported languages.

#### [MODIFY] [login_view.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/modules/auth/login_view.dart)
- Add `LanguagePickerButton` at the top left using `Positioned` inside the background `Stack`.
- Replace hardcoded strings with `.tr` translation keys.

#### [MODIFY] [register_view.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/modules/auth/register_view.dart)
- Add `LanguagePickerButton` at the top left, ensuring it doesn't conflict with the back button.
- Replace hardcoded strings with `.tr` translation keys.

## Verification Plan

### Manual Verification
- Launch the app and verify the language picker is visible on the Login screen.
- Switch to Khmer and verify the "Welcome Back" text and form labels update correctly.
- Switch to Chinese and verify the same.
- Navigate to Register and verify the language remains consistent.
