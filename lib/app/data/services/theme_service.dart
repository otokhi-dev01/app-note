import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService {
  final _storage = GetStorage();
  final _key = 'isDarkMode';

  /// Get isDarkMode info from local storage and return ThemeMode
  ThemeMode get theme => _loadThemeFromStorage();

  /// Load isDarkMode from local storage and if it's empty, returns false (meaning light mode)
  ThemeMode _loadThemeFromStorage() {
    final value = _storage.read(_key);
    if (value == null) return ThemeMode.system;
    return value ? ThemeMode.dark : ThemeMode.light;
  }

  /// Save isDarkMode to local storage
  _saveThemeToStorage(bool isDarkMode) => _storage.write(_key, isDarkMode);

  /// Switch theme and save to local storage
  void switchTheme(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      _storage.remove(_key);
      Get.changeThemeMode(ThemeMode.system);
    } else {
      bool isDark = mode == ThemeMode.dark;
      Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
      _saveThemeToStorage(isDark);
    }
  }
}
