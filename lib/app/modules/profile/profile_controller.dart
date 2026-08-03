import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/services/theme_service.dart';
import '../../routes/app_pages.dart';

class ProfileController extends GetxController {
  final _storage = GetStorage();
  final _themeService = ThemeService();

  final userName = "User Name".obs;
  final userPhone = "0968734812".obs;
  final currentThemeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadCurrentTheme();
  }

  void _loadUserData() {
    // In a real app, read from a UserStore or GetStorage
    // userName.value = _storage.read('userName') ?? "User";
    // userPhone.value = _storage.read('userPhone') ?? "";
  }

  void _loadCurrentTheme() {
    final isDark = _storage.read('isDarkMode');
    if (isDark == null) {
      currentThemeMode.value = ThemeMode.system;
    } else {
      currentThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  void changeTheme(ThemeMode mode) {
    currentThemeMode.value = mode;
    _themeService.switchTheme(mode);
  }

  void logout() {
    _storage.remove('token');
    Get.offAllNamed(Routes.LOGIN);
  }
}
