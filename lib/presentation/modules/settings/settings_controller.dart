import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/data/services/local_storage.dart';
import 'package:notes/data/services/auth_service.dart';
import 'package:notes/app/routes/app_routes.dart';

class SettingsController extends GetxController {
  SettingsController(this._localStorage);

  final LocalStorage _localStorage;
  final isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  Future<void> loadTheme() async {
    isDarkMode.value = await _localStorage.getDarkMode();
  }

  Future<void> toggleDarkMode() async {
    final newValue = !isDarkMode.value;
    isDarkMode.value = newValue;
    await _localStorage.saveDarkMode(newValue);
    Get.changeThemeMode(newValue ? ThemeMode.dark : ThemeMode.light);
  }

  void logout() {
    Get.find<AuthService>().logout();
    Get.offAllNamed(AppRoutes.login);
  }
}
