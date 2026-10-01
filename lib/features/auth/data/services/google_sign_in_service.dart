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
        throw PlatformException(code: 'google_not_configured');
      }
      clientId = config?['clientId'] as String?;
      serverClientId = config?['serverClientId'] as String?;
      final schemes = config?['urlSchemes'] as List<dynamic>? ?? [];
      if (!_validClientId(clientId) ||
          !_validClientId(serverClientId) ||
          !schemes.contains(clientId!.split('.').reversed.join('.'))) {
        throw PlatformException(code: 'google_not_configured');
      }
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      serverClientId = const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
      if (!_validClientId(serverClientId)) {
        throw PlatformException(code: 'google_not_configured');
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
