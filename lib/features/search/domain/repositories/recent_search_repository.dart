abstract interface class RecentSearchRepository {
  Future<List<String>> load({required String? accountScopeId});

  Future<void> save(List<String> searches, {required String? accountScopeId});
}
