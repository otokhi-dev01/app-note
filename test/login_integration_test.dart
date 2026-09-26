import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:Note/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/folder/data/datasources/folder_remote_data_source.dart';
import 'package:Note/features/folder/data/repositories/folder_repository_impl.dart';

class _Device implements AuthDeviceService {
  @override
  Future<AuthDeviceInfo> read() async => const AuthDeviceInfo(
    clientDeviceId: 'fdffb4d7-e037-489f-aa84-a0ea82c138fe',
    appVersion: '1.0.1',
    deviceName: 'Test device',
    platform: 'iOS',
    deviceModel: 'Test model',
  );
}

class _Adapter implements dio.HttpClientAdapter {
  final requests = <dio.RequestOptions>[];
  dio.ResponseBody Function(dio.RequestOptions) respond = (_) => _json({
    'Success': true,
    'Message': 'Login successful',
    'Data': {
      'Token': 'test-session',
      'RefreshToken': 'test-refresh',
      'User': {'Id': 'test-user', 'FullName': 'Test User'},
    },
  });

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

dio.ResponseBody _json(Object? data, [int status = 200]) =>
    dio.ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, String> stored;
  late SessionStorage session;
  late _Adapter adapter;
  late Login login;
  Future<Object?> Function(MethodCall)? overrideStorage;

  Future<Object?> storage(MethodCall call) async {
    final args = Map<String, dynamic>.from(call.arguments as Map);
    switch (call.method) {
      case 'read':
        return stored[args['key']];
      case 'write':
        stored[args['key'] as String] = args['value'] as String;
        return null;
      case 'delete':
        stored.remove(args['key']);
        return null;
      case 'deleteAll':
        stored.clear();
        return null;
      default:
        return null;
    }
  }

  setUp(() async {
    Get.testMode = true;
    stored = {};
    overrideStorage = null;
    messenger.setMockMethodCallHandler(
      channel,
      (call) =>
          overrideStorage != null ? overrideStorage!(call) : storage(call),
    );
    session = Get.put(SessionStorage());
    await session.loadSession();
    final api = Get.put(ApiClient());
    adapter = _Adapter();
    api.dio.httpClientAdapter = adapter;
    login = Login(
      AuthRepositoryImpl(
        AuthRemoteDataSource(api: api, deviceService: _Device()),
        session,
      ),
    );
  });

  tearDown(() {
    Get.reset();
    messenger.setMockMethodCallHandler(channel, null);
  });

  const params = LoginParams(
    account: ' someone@example.com ',
    password: ' password with spaces ',
  );

  test(
    'Uses only documented login fields and publishes user before persisted token',
    () async {
      String? userSeenAtToken;
      final worker = ever(
        session.token,
        (_) => userSeenAtToken = session.user.value?.id,
      );
      addTearDown(worker.dispose);
      final result = await login(params);
      expect(result.isOk, isTrue);
      expect(session.isLoggedIn, isTrue);
      expect(stored['token'], 'test-session');
      expect(stored['refresh_token'], 'test-refresh');
      expect(userSeenAtToken, 'test-user');
      final request = adapter.requests.single;
      expect(request.uri.toString(), 'https://chat.piisiit.com/api/auth/login');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.data, {
        'account': 'someone@example.com',
        'password': ' password with spaces ',
        'clientDeviceId': 'fdffb4d7-e037-489f-aa84-a0ea82c138fe',
        'appVersion': '1.0.1',
        'deviceName': 'Test device',
        'platform': 'iOS',
        'deviceModel': 'Test model',
      });
    },
  );

  test(
    'Chat login supplies the bearer token for Note reads and folder saves',
    () async {
      final signIn = adapter.respond;
      adapter.respond = (request) {
        if (request.uri.path == '/api/auth/login') {
          expect(request.uri.origin, 'https://chat.piisiit.com');
          return signIn(request);
        }
        expect(request.uri.origin, ApiClient.baseUrl);
        expect(request.headers['Authorization'], 'Bearer test-session');
        if (request.uri.path == '/api/folder/save') {
          expect(request.method, 'POST');
          expect(request.data, {
            'id': adapter.requests.length == 3 ? 0 : 42,
            'name': 'Work',
            'iconName': 'folder',
            'colorValue': 'blue',
            'sortOrder': 0,
            'parentFolderId': null,
          });
          return _json({
            'code': 200,
            'message': 'Folder saved successfully.',
            'data': null,
          });
        }
        return _json({'code': 200, 'data': []});
      };
      expect((await login(params)).isOk, isTrue);
      await Get.find<ApiClient>().dio.get('/api/note');
      final folders = FolderRepositoryImpl(FolderRemoteDataSource());
      for (final id in [0, 42]) {
        final result = await folders.saveFolder(
          id: id,
          name: 'Work',
          iconName: 'folder',
          colorValue: 'blue',
        );
        expect(result.isOk, isTrue);
      }
      expect(adapter.requests, hasLength(4));
    },
  );

  test(
    'Login persists the normalized access token and sends one Bearer prefix',
    () async {
      final rawToken =
          '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.'
          '${base64Url.encode(utf8.encode('{"iss":"PiisiitChat","aud":"PiisiitClient"}'))}.'
          '${base64Url.encode(utf8.encode('test-signature'))}';
      adapter.respond = (request) {
        if (request.uri.path == '/api/auth/login') {
          return _json({
            'success': true,
            'data': {
              'token': 'wrong-generic-token',
              'accessToken': '  bEaReR Bearer $rawToken \n',
              'refreshToken': 'separate-refresh',
            },
          });
        }
        expect(request.uri.host, 'note.piisiit.com');
        expect(request.headers['Authorization'], 'Bearer $rawToken');
        expect(
          request.headers.keys.where(
            (key) => key.toLowerCase() == 'authorization',
          ),
          hasLength(1),
        );
        return _json({'data': []});
      };
      final output = <String>[];
      final originalPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) output.add(message);
      };
      addTearDown(() => debugPrint = originalPrint);
      final result = await login(params);
      expect(result.valueOrNull?.token, rawToken);
      expect(stored['token'], rawToken);
      expect(stored['refresh_token'], 'separate-refresh');
      final response = await Get.find<ApiClient>().dio.get(
        '/api/note',
        options: dio.Options(
          headers: {
            'authorization': 'Bearer stale',
            'Authorization': 'Bearer Bearer stale',
          },
        ),
      );
      expect(response.statusCode, 200);
      expect(output.join('\n'), contains('"bearerPrefixRemoved":true'));
      expect(output.join('\n'), contains('"duplicateBearerPrefix":true'));
      expect(output.join('\n'), isNot(contains(rawToken)));
      expect(output.join('\n'), isNot(contains('separate-refresh')));
    },
  );

  test('Prefix-only login token cannot create a session', () async {
    adapter.respond = (_) =>
        _json({'success': true, 'accessToken': ' Bearer bearer '});
    expect(
      (await login(params)).failureOrNull?.message,
      contains('did not return a sign-in token'),
    );
    expect(session.isLoggedIn, isFalse);
    expect(stored, isEmpty);
  });

  test(
    'Requests wait for a new login write before choosing token and revision',
    () async {
      expect((await login(params)).isOk, isTrue);
      final started = Completer<void>();
      final release = Completer<void>();
      overrideStorage = (call) async {
        if (call.method == 'write' && call.arguments['key'] == 'token') {
          started.complete();
          await release.future;
        }
        return storage(call);
      };
      adapter.respond = (request) {
        if (request.uri.path == '/api/auth/login') {
          return _json({'success': true, 'accessToken': 'second-access'});
        }
        expect(request.headers['Authorization'], 'Bearer second-access');
        expect(request.extra['authSessionRevision'], session.revision);
        return _json({'data': []});
      };
      final signingIn = login(params);
      await started.future;
      final reading = Get.find<ApiClient>().dio.get('/api/note');
      await Future<void>.delayed(Duration.zero);
      expect(adapter.requests.where((r) => r.uri.path == '/api/note'), isEmpty);
      release.complete();
      expect((await signingIn).isOk, isTrue);
      expect((await reading).statusCode, 200);
      expect(stored['token'], 'second-access');
    },
  );

  test('Server error bodies cannot echo credentials into debug logs', () async {
    final output = <String>[];
    final originalPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) output.add(message);
    };
    addTearDown(() => debugPrint = originalPrint);
    const echoedSecret =
        'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJwcml2YXRlIn0.c2VjcmV0';
    adapter.respond = (_) =>
        _json({'message': 'Server exception: $echoedSecret'}, 500);
    try {
      await Get.find<ApiClient>().dio.get('/api/note');
      fail('Expected HTTP 500');
    } on dio.DioException catch (error) {
      ApiErrorParser.toException(error);
    }
    expect(output.join('\n'), isNot(contains(echoedSecret)));
  });

  test(
    'Registration and authenticated account operations stay on Chat',
    () async {
      final remote = AuthRemoteDataSource(
        api: Get.find<ApiClient>(),
        deviceService: _Device(),
      );
      await remote.register('someone@example.com', 'password');
      final registration = adapter.requests.single;
      expect(
        registration.uri.toString(),
        'https://chat.piisiit.com/api/auth/register',
      );
      expect(registration.headers['Authorization'], isNull);
      expect(registration.data['account'], 'someone@example.com');
      expect(registration.data.containsKey('phone'), isFalse);
      expect((await login(params)).isOk, isTrue);
      await remote.logout();
      expect(
        adapter.requests.last.uri.toString(),
        'https://chat.piisiit.com/api/auth/logout-current-device',
      );
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer test-session',
      );
    },
  );

  test(
    'Live HTTP 500 invalid-credential envelope is an authentication rejection',
    () async {
      adapter.respond = (_) => _json({
        'Success': false,
        'Message': 'Invalid credential!',
        'Data': null,
        'Errors': null,
      }, 500);
      final result = await login(params);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(
        result.failureOrNull?.message,
        contains('Invalid account or password'),
      );
      expect(session.isLoggedIn, isFalse);
      expect(stored, isEmpty);
      expect(adapter.requests, hasLength(1));
    },
  );

  test(
    'Real server errors, malformed payloads and missing tokens remain backend failures',
    () async {
      adapter.respond = (_) =>
          _json({'success': false, 'message': 'Service unavailable'}, 500);
      expect((await login(params)).failureOrNull, isA<ServerFailure>());
      adapter.respond = (_) => _json('Proxy response');
      expect(
        (await login(params)).failureOrNull?.message,
        contains('invalid response'),
      );
      adapter.respond = (_) =>
          _json({'Success': true, 'Message': 'Login successful', 'Data': {}});
      expect(
        (await login(params)).failureOrNull?.message,
        contains('did not return a sign-in token'),
      );
      expect(session.isLoggedIn, isFalse);
      expect(stored, isEmpty);
    },
  );

  test(
    'Secure-storage failure cannot leave a signed-in session and retry succeeds',
    () async {
      overrideStorage = (call) async {
        if (call.method == 'write' && call.arguments['key'] == 'token') {
          throw PlatformException(code: 'storage_unavailable');
        }
        return storage(call);
      };
      final result = await login(params);
      expect(result.failureOrNull, isA<StorageFailure>());
      expect(session.isLoggedIn, isFalse);
      expect(session.user.value, isNull);
      expect(stored, isEmpty);
      overrideStorage = null;
      expect((await login(params)).isOk, isTrue);
    },
  );

  test(
    'A slow session restore does not overwrite a newly successful login',
    () async {
      final started = Completer<void>();
      final delayedToken = Completer<String?>();
      var delayed = false;
      overrideStorage = (call) async {
        if (call.method == 'read' &&
            call.arguments['key'] == 'token' &&
            !delayed) {
          delayed = true;
          started.complete();
          return delayedToken.future;
        }
        return storage(call);
      };
      final restoring = session.loadSession();
      await started.future;
      expect((await login(params)).isOk, isTrue);
      delayedToken.complete('old-session');
      await restoring;
      expect(session.token.value, 'test-session');
      expect(session.user.value?.id, 'test-user');
    },
  );

  test(
    'Sign-out during a pending secure write does not resurrect the session',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      overrideStorage = (call) async {
        if (call.method == 'write' && call.arguments['key'] == 'token') {
          started.complete();
          await release.future;
        }
        return storage(call);
      };
      final signingIn = login(params);
      await started.future;
      final signingOut = session.clearSession();
      release.complete();
      expect((await signingIn).isErr, isTrue);
      await signingOut;
      expect(session.isLoggedIn, isFalse);
      expect(stored, isEmpty);
    },
  );
  test(
    'Successful login restores with a fresh session instance after restart',
    () async {
      expect((await login(params)).isOk, isTrue);
      final restarted = SessionStorage();
      expect(restarted.isLoggedIn, isFalse);
      await restarted.ready;
      expect(restarted.isLoggedIn, isTrue);
      expect(restarted.token.value, 'test-session');
      expect(restarted.refreshToken.value, 'test-refresh');
      expect(restarted.user.value?.id, 'test-user');
    },
  );

  test(
    'Storage that silently ignores writes cannot report a successful login',
    () async {
      overrideStorage = (call) async =>
          call.method == 'write' ? null : storage(call);
      expect((await login(params)).failureOrNull, isA<StorageFailure>());
      expect(session.isLoggedIn, isFalse);
      expect(stored, isEmpty);
    },
  );

  test(
    'Sign-out removes credentials but preserves ID records and encryption keys',
    () async {
      expect((await login(params)).isOk, isTrue);
      stored['profile_id_test_snapshot'] = 'saved identity';
      stored['private_key_test'] = 'saved key';
      await session.clearSession();
      expect(stored, {
        'profile_id_test_snapshot': 'saved identity',
        'private_key_test': 'saved key',
      });
      final restarted = SessionStorage();
      await restarted.ready;
      expect(restarted.isLoggedIn, isFalse);
    },
  );
}
