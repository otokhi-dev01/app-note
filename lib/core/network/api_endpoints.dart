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

  static String get baseUrl =>
      _localBaseUrl.trim().isNotEmpty ? _localBaseUrl : _productionBaseUrl;

  static String get login => '${_normalizedBaseUrl()}/api/auth/login';
  static String get register => '${_normalizedBaseUrl()}/api/auth/register';
  static String get folders => '${_normalizedBaseUrl()}/api/folder';
  static String get saveFolder => '${_normalizedBaseUrl()}/api/folder/save';
  static String get deleteRestoreFolder =>
      '${_normalizedBaseUrl()}/api/folder/delete-restore';
  static String get notes => '${_normalizedBaseUrl()}/api/note';
  static String note(int id) => '${_normalizedBaseUrl()}/api/note/$id';
  static String get saveNoteContent =>
      '${_normalizedBaseUrl()}/api/note/save-content';
  static String get updateNoteState =>
      '${_normalizedBaseUrl()}/api/note/update-state';

  static String _normalizedBaseUrl() {
    final value = baseUrl.trim();
    if (value.isEmpty) {
      throw const FormatException(
        'No notes API host is configured. Start the app with '
        '--dart-define=PIISIIT_NOTE_LOCAL=https://your-local-api-host.com '
        'or --dart-define=PIISIIT_NOTE_PROD=https://your-api-host.com',
      );
    }

    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
