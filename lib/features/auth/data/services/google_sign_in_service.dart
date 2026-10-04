import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

typedef GoogleSignInFactory =
    GoogleSignIn Function({String? clientId, String? serverClientId});

/// Checks native setup before entering the Google SDK, whose iOS configuration
/// exceptions can terminate the process and cannot be caught by Dart.
class GoogleSignInService {
  GoogleSignInService({GoogleSignInFactory? createClient})
    : _createClient = createClient ?? _defaultClient;

  static const configurationChannel = MethodChannel(
    'com.kimchheang.pii_note/google_sign_in_config',
  );
  final GoogleSignInFactory _createClient;

  static GoogleSignIn _defaultClient({
    String? clientId,
    String? serverClientId,
  }) => GoogleSignIn(
    clientId: clientId,
    serverClientId: serverClientId,
    scopes: const ['email', 'profile'],
  );

  static bool _validClientId(String? value) =>
      value != null &&
      RegExp(r'^[a-zA-Z0-9-]+\.apps\.googleusercontent\.com$').hasMatch(value);

  static PlatformException _configurationError(List<String> missing) {
    if (kDebugMode) {
      debugPrint('[GOOGLE] Configuration incomplete: ${missing.join(', ')}');
    }
    return PlatformException(
      code: 'google_not_configured',
      message: 'Google OAuth configuration is incomplete.',
      details: {'missing': missing},
    );
  }

  Future<String?> signInIdToken() async {
    String? clientId;
    String? serverClientId;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      Map<String, dynamic>? config;
      try {
        config = await configurationChannel.invokeMapMethod<String, dynamic>(
          'readConfiguration',
        );
      } on MissingPluginException {
        throw _configurationError(['nativeConfigurationBridge']);
      }
      clientId = (config?['clientId'] as String?)?.trim();
      serverClientId = (config?['serverClientId'] as String?)?.trim();
      final schemes = config?['urlSchemes'] as List<dynamic>? ?? [];
      final missing = <String>[
        if (!_validClientId(clientId)) 'iosClientId',
        if (!_validClientId(serverClientId)) 'serverClientId',
        if (_validClientId(clientId) &&
            !schemes.contains(clientId!.split('.').reversed.join('.')))
          'callbackScheme',
      ];
      if (missing.isNotEmpty) {
        throw _configurationError(missing);
      }
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      serverClientId = const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
      ).trim();
      if (!_validClientId(serverClientId)) {
        throw _configurationError(['serverClientId']);
      }
    } else {
      throw PlatformException(code: 'google_not_configured');
    }

    final client = _createClient(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    final account = await client.signIn();
    if (account == null) return null;
    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    // An OAuth access token is not an ID token for backend authentication.
    if (idToken == null || idToken.trim().isEmpty) {
      throw PlatformException(code: 'google_missing_id_token');
    }
    return idToken;
  }
}
