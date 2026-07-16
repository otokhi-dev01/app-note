import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/data/services/local_storage.dart';
import 'package:notes/data/services/auth_service.dart';
import 'package:notes/app/routes/app_routes.dart';

class SettingsController extends GetxController {
  SettingsController(this._localStorage);

  final LocalStorage _localStorage;
  final themeMode = ThemeMode.system.obs;

  String get themeModeLabel => switch (themeMode.value) {
    ThemeMode.system => 'System Default',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  String get accountIdentifier {
    final user = Get.find<AuthService>().user;
    final phone = user?.phone?.trim();
    if (phone != null && phone.isNotEmpty) return phone;

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return 'Authenticated account';
  }

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  Future<void> loadTheme() async {
    themeMode.value = await _localStorage.getThemeMode();
    Get.changeThemeMode(themeMode.value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    await _localStorage.saveThemeMode(mode);
  }

  Future<void> logout() async {
    await Get.find<AuthService>().logout();
    Get.offAllNamed(AppRoutes.login);
  }
}
