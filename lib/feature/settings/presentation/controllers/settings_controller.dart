import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

enum AppLanguage { english, khmer }

class SettingsController extends GetxController {
  static const String _themeKey = 'app_theme_mode';
  static const String _languageKey = 'app_language';

  final GetStorage _storage = GetStorage();

  final Rx<ThemeMode> selectedThemeMode = ThemeMode.system.obs;

  final Rx<AppLanguage> selectedLanguage = AppLanguage.english.obs;

  ThemeMode get themeMode {
    return selectedThemeMode.value;
  }

  AppLanguage get language {
    return selectedLanguage.value;
  }

  Locale get currentLocale {
    switch (selectedLanguage.value) {
      case AppLanguage.english:
        return const Locale('en', 'US');

      case AppLanguage.khmer:
        return const Locale('km', 'KH');
    }
  }

  String? get fontFamily {
    switch (selectedLanguage.value) {
      case AppLanguage.english:
        // Uses the system font:
        // SF Pro on iOS and Roboto on Android.
        return null;

      case AppLanguage.khmer:
        return 'NotoSansKhmer';
    }
  }

  bool get isEnglish {
    return selectedLanguage.value == AppLanguage.english;
  }

  bool get isKhmer {
    return selectedLanguage.value == AppLanguage.khmer;
  }

  @override
  void onInit() {
    super.onInit();

    _loadSavedTheme();
    _loadSavedLanguage();
  }

  void _loadSavedTheme() {
    final String? savedTheme = _storage.read<String>(_themeKey);

    switch (savedTheme) {
      case 'light':
        selectedThemeMode.value = ThemeMode.light;
        break;

      case 'dark':
        selectedThemeMode.value = ThemeMode.dark;
        break;

      default:
        selectedThemeMode.value = ThemeMode.system;
    }
  }

  void _loadSavedLanguage() {
    final String? savedLanguage = _storage.read<String>(_languageKey);

    switch (savedLanguage) {
      case 'khmer':
        selectedLanguage.value = AppLanguage.khmer;
        break;

      default:
        selectedLanguage.value = AppLanguage.english;
    }
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    selectedThemeMode.value = mode;

    await _storage.write(_themeKey, _themeModeToStorageValue(mode));

    Get.changeThemeMode(mode);
  }

  Future<void> changeLanguage(AppLanguage language) async {
    selectedLanguage.value = language;

    await _storage.write(
      _languageKey,
      language == AppLanguage.khmer ? 'khmer' : 'english',
    );

    await Get.updateLocale(currentLocale);
  }

  String _themeModeToStorageValue(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';

      case ThemeMode.dark:
        return 'dark';

      case ThemeMode.system:
        return 'system';
    }
  }
}
