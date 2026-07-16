import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/data/services/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new installs use the system theme by default', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await LocalStorage().getThemeMode(), ThemeMode.system);
  });

  test('selected appearance is restored', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage();

    await storage.saveThemeMode(ThemeMode.dark);
    expect(await storage.getThemeMode(), ThemeMode.dark);

    await storage.saveThemeMode(ThemeMode.light);
    expect(await storage.getThemeMode(), ThemeMode.light);
  });

  test('legacy dark mode preference is migrated', () async {
    SharedPreferences.setMockInitialValues({'dark_mode': true});

    expect(await LocalStorage().getThemeMode(), ThemeMode.dark);
  });
}
