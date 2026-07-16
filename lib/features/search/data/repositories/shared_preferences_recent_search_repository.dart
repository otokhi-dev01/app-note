import 'package:notes/features/search/domain/repositories/recent_search_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesRecentSearchRepository
    implements RecentSearchRepository {
  static const _keyPrefix = 'recent_searches_';

  String _key(String? accountScopeId) => '$_keyPrefix$accountScopeId';

  @override
  Future<List<String>> load({required String? accountScopeId}) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key(accountScopeId)) ?? const [];
  }

  @override
  Future<void> save(
    List<String> searches, {
    required String? accountScopeId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key(accountScopeId), searches);
  }
}
