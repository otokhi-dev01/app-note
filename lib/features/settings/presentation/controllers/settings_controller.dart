import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes/features/settings/domain/entities/theme_preference.dart';
import 'package:notes/features/settings/domain/repositories/theme_repository.dart';

class SettingsController extends GetxController {
  SettingsController(this._themeRepository, this._authRepository);

  final ThemeRepository _themeRepository;
  final AuthRepository _authRepository;
  final themeMode = ThemeMode.system.obs;
  final isSigningOut = false.obs;
  int _themeRequest = 0;

  String get themeModeLabel => switch (themeMode.value) {
    ThemeMode.system => 'System Default',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  String get accountIdentifier {
    final user = _authRepository.user;
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
    final request = ++_themeRequest;
    final loadedMode = (await _themeRepository.load()).themeMode;
    if (request != _themeRequest || isClosed) return;
    themeMode.value = loadedMode;
    Get.changeThemeMode(loadedMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final previousMode = themeMode.value;
    ++_themeRequest;
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    try {
      await _themeRepository.save(mode.preference);
    } catch (_) {
      if (isClosed) rethrow;
      themeMode.value = previousMode;
      Get.changeThemeMode(previousMode);
      rethrow;
    }
  }

  Future<void> logout() async {
    if (isSigningOut.value) return;
    isSigningOut.value = true;
    try {
      await _authRepository.logout();
      if (!isClosed) Get.offAllNamed(AppRoutes.login);
    } finally {
      if (!isClosed) isSigningOut.value = false;
    }
  }
}

extension on ThemeMode {
  ThemePreference get preference => switch (this) {
    ThemeMode.system => ThemePreference.system,
    ThemeMode.light => ThemePreference.light,
    ThemeMode.dark => ThemePreference.dark,
  };
}

extension on ThemePreference {
  ThemeMode get themeMode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
}
