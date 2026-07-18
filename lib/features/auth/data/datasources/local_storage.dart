import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class LocalStorage {
  LocalStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _darkModeKey = 'dark_mode';
  static const _themeModeKey = 'theme_mode';
  static const _authUserKey = 'auth_user';
  static const _signedOutKey = 'auth_signed_out';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveDarkMode(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, value);
  }

  Future<bool> getDarkMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_darkModeKey) ?? false;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, mode.name);
  }

  Future<ThemeMode> getThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_themeModeKey);

    if (savedMode != null) {
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => ThemeMode.system,
      );
    }

    // Migrate the previous two-state setting. A new install defaults to System.
    final legacyDarkMode = preferences.getBool(_darkModeKey);
    if (legacyDarkMode != null) {
      final migratedMode = legacyDarkMode ? ThemeMode.dark : ThemeMode.light;
      await preferences.setString(_themeModeKey, migratedMode.name);
      return migratedMode;
    }

    return ThemeMode.system;
  }

  Future<void> saveAuthUser(UserModel user) async {
    final preferences = await SharedPreferences.getInstance();
    await _secureStorage.write(
      key: _authUserKey,
      value: jsonEncode(user.toJson()),
    );
    await preferences.remove(_authUserKey);
    await preferences.remove(_signedOutKey);
  }

  Future<UserModel?> getAuthUser() async {
    SharedPreferences? preferences;
    try {
      preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(_signedOutKey) == true) {
        try {
          await _secureStorage.delete(key: _authUserKey);
        } catch (_) {}
        await preferences.remove(_authUserKey);
        return null;
      }

      var value = await _secureStorage.read(key: _authUserKey);
      final isLegacyValue = value == null;
      value ??= preferences.getString(_authUserKey);
      if (value == null) return null;

      final decoded = jsonDecode(value);
      if (decoded is! Map) {
        throw const FormatException('Invalid stored session.');
      }
      final user = UserModel.fromJson(
        decoded.map((key, item) => MapEntry(key.toString(), item)),
      );

      if (isLegacyValue) {
        await _secureStorage.write(key: _authUserKey, value: value);
        await preferences.remove(_authUserKey);
      }
      return user;
    } catch (_) {
      try {
        await _secureStorage.delete(key: _authUserKey);
      } catch (_) {}
      try {
        preferences ??= await SharedPreferences.getInstance();
        await preferences.remove(_authUserKey);
      } catch (_) {}
      return null;
    }
  }

  Future<void> clearAuthUser() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_signedOutKey, true);
    await preferences.remove(_authUserKey);
    try {
      await _secureStorage.delete(key: _authUserKey);
    } catch (_) {}
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setBool(_signedOutKey, true);
    try {
      await _secureStorage.delete(key: _authUserKey);
    } catch (_) {}
  }
}
