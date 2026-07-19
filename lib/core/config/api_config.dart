abstract final class ApiConfig {
  /// Main API server used by folders and notes.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://note.piisiit.com',
  );

  /// Authentication server.
  ///
  /// Set this to the same URL as API_BASE_URL when authentication
  /// and note APIs run on the same backend.
  static const String authBaseUrl = String.fromEnvironment(
    'AUTH_BASE_URL',
    defaultValue: 'https://note.piisiit.com',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}