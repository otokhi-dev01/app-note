import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// The two languages the app ships with. The `code` is what's persisted and
/// what [AppTranslations]'s keys are looked up under.
enum AppLanguage {
  english('en_US', Locale('en', 'US'), 'English', '🇬🇧'),
  khmer('km_KH', Locale('km', 'KH'), 'ខ្មែរ', '🇰🇭');

  final String code;
  final Locale locale;
  final String label;
  final String flag;

  const AppLanguage(this.code, this.locale, this.label, this.flag);

  static AppLanguage fromCode(String? code) => values.firstWhere(
    (l) => l.code == code,
    orElse: () => AppLanguage.english,
  );
}

/// Persisted UI language, read once by [NoteApp] on startup and updated live
/// via [Get.updateLocale] whenever the user changes it in Settings.
class LanguagePreferences {
  final _storage = GetStorage();
  static const _key = 'appLanguage';

  AppLanguage get language => AppLanguage.fromCode(_storage.read(_key));

  Locale get locale => language.locale;

  void setLanguage(AppLanguage language) {
    _storage.write(_key, language.code);
    Get.updateLocale(language.locale);
  }
}
