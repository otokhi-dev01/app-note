import 'package:flutter/material.dart';
import 'package:notes/features/auth/data/datasources/local_storage.dart';
import 'package:notes/features/settings/domain/entities/theme_preference.dart';
import 'package:notes/features/settings/domain/repositories/theme_repository.dart';

final class LocalThemeRepository implements ThemeRepository {
  const LocalThemeRepository(this._localStorage);

  final LocalStorage _localStorage;

  @override
  Future<ThemePreference> load() async {
    final mode = await _localStorage.getThemeMode();
    return switch (mode) {
      ThemeMode.system => ThemePreference.system,
      ThemeMode.light => ThemePreference.light,
      ThemeMode.dark => ThemePreference.dark,
    };
  }

  @override
  Future<void> save(ThemePreference preference) {
    return _localStorage.saveThemeMode(preference.themeMode);
  }
}

extension on ThemePreference {
  ThemeMode get themeMode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
}
