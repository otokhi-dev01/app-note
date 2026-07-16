abstract final class ApiConfig {
  static const minimumPhoneLength = 8;
  static const maximumPhoneLength = 55;
  static const minimumPasswordLength = 6;
  static const maximumPasswordLength = 100;

  static const baseUrl = String.fromEnvironment(
    'PIISIIT_NOTE_PROD',
    defaultValue: 'https://note.piisiit.com',
  );

  static String get loginUrl => '${_normalizedBaseUrl()}/api/auth/login';
  static String get registerUrl => '${_normalizedBaseUrl()}/api/auth/register';

  static String _normalizedBaseUrl() {
    final value = baseUrl.trim();
    if (value.isEmpty) {
      throw const FormatException(
        'PIISIIT_NOTE_PROD is not configured. Start the app with '
        '--dart-define=PIISIIT_NOTE_PROD=https://your-api-host.com',
      );
    }

    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
