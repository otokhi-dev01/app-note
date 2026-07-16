import 'package:notes/features/settings/domain/entities/theme_preference.dart';

abstract interface class ThemeRepository {
  Future<ThemePreference> load();

  Future<void> save(ThemePreference preference);
}
