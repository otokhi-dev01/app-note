import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/storage/theme_storage.dart';

class AppearanceController extends GetxController {
  final _theme = ThemeStorage();

  final currentThemeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    currentThemeMode.value = _theme.theme;
  }

  void changeTheme(ThemeMode mode) {
    currentThemeMode.value = mode;
    _theme.switchTheme(mode);
  }
}
