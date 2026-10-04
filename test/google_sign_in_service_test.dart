import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:Note/features/auth/data/services/google_sign_in_service.dart';

class _Client extends GoogleSignIn {
  GoogleSignInAccount? account;
  Object? error;
  int calls = 0;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    calls++;
    if (error != null) throw error!;
    return account;
  }
}

class _Account implements GoogleSignInAccount {
  _Account(this.token);
  final String? token;
  @override
  Future<GoogleSignInAuthentication> get authentication async => _Tokens(token);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tokens implements GoogleSignInAuthentication {
  _Tokens(this.idToken);
  @override
  final String? idToken;
  @override
  String get accessToken => 'access-token-must-never-be-used-as-id-token';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late _Client client;
  late GoogleSignInService service;
  late Map<String, dynamic> config;
  const iosId = '123-ios.apps.googleusercontent.com';
  const serverId = '123-web.apps.googleusercontent.com';
  int creations = 0;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    client = _Client();
    creations = 0;
    config = {
      'clientId': iosId,
      'serverClientId': serverId,
      'urlSchemes': ['com.googleusercontent.apps.123-ios'],
    };
    messenger.setMockMethodCallHandler(
      GoogleSignInService.configurationChannel,
      (_) async => config,
    );
    service = GoogleSignInService(
      createClient: ({clientId, serverClientId}) {
        creations++;
        expect(clientId, iosId);
        expect(serverClientId, serverId);
        return client;
      },
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(
      GoogleSignInService.configurationChannel,
      null,
    );
  });

  test(
    'Missing OAuth IDs or callback scheme never enter the native SDK',
    () async {
      final valid = Map<String, dynamic>.from(config);
      for (final invalid in [
        <String, dynamic>{},
        {...valid, 'clientId': ''},
        {...valid, 'clientId': r'$(GOOGLE_IOS_CLIENT_ID)'},
        {...valid, 'serverClientId': ''},
        {
          ...valid,
          'urlSchemes': ['incorrect-scheme'],
        },
      ]) {
        config = invalid;
        await expectLater(
          service.signInIdToken(),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'google_not_configured',
            ),
          ),
        );
      }
      expect(creations, 0);
      expect(client.calls, 0);
    },
  );

  test('Missing native configuration bridge fails safely', () async {
    messenger.setMockMethodCallHandler(
      GoogleSignInService.configurationChannel,
      null,
    );
    await expectLater(
      service.signInIdToken(),
      throwsA(isA<PlatformException>()),
    );
    expect(creations, 0);
  });

  test('Cancellation returns without authenticating', () async {
    expect(await service.signInIdToken(), isNull);
    expect(client.calls, 1);
  });

  test('Configured sign-in returns the Google ID token', () async {
    client.account = _Account('google-id-token');
    expect(await service.signInIdToken(), 'google-id-token');
  });

  test('Whitespace around configured client IDs is ignored', () async {
    config['clientId'] = ' $iosId\n';
    config['serverClientId'] = ' $serverId ';
    client.account = _Account('google-id-token');
    expect(await service.signInIdToken(), 'google-id-token');
  });

  test(
    'Configuration failures identify missing IDs and callback scheme',
    () async {
      for (final entry in [
        (<String, dynamic>{}, ['iosClientId', 'serverClientId']),
        ({...config, 'serverClientId': ''}, ['serverClientId']),
        ({...config, 'urlSchemes': <String>[]}, ['callbackScheme']),
      ]) {
        final original = config;
        config = entry.$1;
        await expectLater(
          service.signInIdToken(),
          throwsA(
            isA<PlatformException>().having(
              (error) => error.details,
              'configuration details',
              {'missing': entry.$2},
            ),
          ),
        );
        config = original;
      }
      expect(creations, 0);
    },
  );

  test('An access token cannot substitute for a missing ID token', () async {
    client.account = _Account(null);
    await expectLater(
      service.signInIdToken(),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'google_missing_id_token',
        ),
      ),
    );
  });

  test('A failed sign-in can be retried', () async {
    client.error = PlatformException(code: 'network_error');
    await expectLater(
      service.signInIdToken(),
      throwsA(isA<PlatformException>()),
    );
    client.error = null;
    client.account = _Account('retry-id-token');
    expect(await service.signInIdToken(), 'retry-id-token');
  });
}
