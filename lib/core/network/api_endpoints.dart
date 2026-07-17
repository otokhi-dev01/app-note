abstract final class ApiEndpoints {
  static const minimumPhoneLength = 8;
  static const maximumPhoneLength = 55;
  static const minimumPasswordLength = 6;
  static const maximumPasswordLength = 100;

  static const _localBaseUrl = String.fromEnvironment(
    'PIISIIT_NOTE_LOCAL',
    defaultValue: String.fromEnvironment('piisiit_note_local'),
  );

  static const _productionBaseUrl = String.fromEnvironment(
    'PIISIIT_NOTE_PROD',
    defaultValue: 'https://note.piisiit.com',
  );

  static String get _configuredBaseUrl =>
      _localBaseUrl.trim().isNotEmpty ? _localBaseUrl : _productionBaseUrl;

  static String get baseUrl =>
      ApiEndpointResolver(_configuredBaseUrl).baseUrl;

  static String get login => _endpoint('/api/auth/login');
  static String get register => _endpoint('/api/auth/register');
  static String get folders => _endpoint('/api/folder');
  static String get saveFolder => _endpoint('/api/folder/save');
  static String get deleteRestoreFolder =>
      _endpoint('/api/folder/delete-restore');
  static String get notes => _endpoint('/api/note');
  static String note(int id) => _endpoint('/api/note/$id');
  static String get saveNoteContent => _endpoint('/api/note/save-content');
  static String get updateNoteState => _endpoint('/api/note/update-state');

  static String _endpoint(String path) =>
      ApiEndpointResolver(_configuredBaseUrl).endpoint(path);
}

/// Validates the configured API origin and joins it with an API route.
///
/// Keeping this separate from the compile-time Dart defines makes endpoint
/// behavior deterministic and directly testable.
final class ApiEndpointResolver {
  ApiEndpointResolver(String rawBaseUrl) : _baseUri = _parse(rawBaseUrl);

  final Uri _baseUri;

  String get baseUrl {
    final path = _baseUri.path.replaceFirst(RegExp(r'/+$'), '');
    return _baseUri.replace(path: path).toString();
  }

  String endpoint(String route) {
    final normalizedRoute = route.trim().replaceFirst(RegExp(r'^/+'), '');
    if (normalizedRoute.isEmpty) {
      throw const FormatException('An API route cannot be empty.');
    }

    final basePath = _baseUri.path.replaceFirst(RegExp(r'/+$'), '');
    return _baseUri
        .replace(path: '$basePath/$normalizedRoute')
        .toString();
  }

  static Uri _parse(String rawBaseUrl) {
    final value = rawBaseUrl.trim();
    if (value.isEmpty) {
      throw const FormatException(
        'No notes API host is configured. Start the app with '
        '--dart-define=PIISIIT_NOTE_LOCAL=https://your-local-api-host.com '
        'or --dart-define=PIISIIT_NOTE_PROD=https://your-api-host.com',
      );
    }

    final uri = Uri.tryParse(value);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        (scheme != 'http' && scheme != 'https') ||
        !uri.hasAuthority ||
        uri.host.isEmpty) {
      throw FormatException(
        'The notes API host must be an absolute http or https URL: $value',
      );
    }
    if (uri.hasQuery || uri.hasFragment) {
      throw const FormatException(
        'The notes API host cannot contain a query string or fragment.',
      );
    }

    return uri.replace(scheme: scheme);
  }
}
