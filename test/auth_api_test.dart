import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:Note/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GetStorage storage;
  late SessionStorage session;
  late ApiClient api;
  late _LoginAdapter adapter;
  late Login login;
  late Register register;

  AuthDeviceService deviceService() => AuthDeviceService(
    storage: storage,
    packageInfo: () async => PackageInfo(
      appName: 'Pii Note',
      packageName: 'com.kimchheang.otokhi-note',
      version: '1.0.2',
      buildNumber: '3',
    ),
    deviceInfo: () async => IosDeviceInfo.fromMap({
      'name': 'iPhone',
      'systemName': 'iOS',
      'systemVersion': '26.0',
      'model': 'iPhone',
      'modelName': 'iPhone 16 Pro',
      'localizedModel': 'iPhone',
      'freeDiskSize': 1000,
      'totalDiskSize': 2000,
      'isPhysicalDevice': true,
      'physicalRamSize': 8000,
      'availableRamSize': 2000,
      'isiOSAppOnMac': false,
      'isiOSAppOnVision': false,
      'utsname': {
        'sysname': 'Darwin',
        'nodename': 'iPhone',
        'release': '25.0',
        'version': 'Darwin',
        'machine': 'iPhone17,1',
      },
    }),
  );

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    final directory = await Directory.systemTemp.createTemp('pii-login-test-');
    storage = GetStorage(
      'login-${directory.path.split('/').last}',
      directory.path,
    );
    await storage.initStorage;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    session = Get.put(SessionStorage());
    await session.loadSession();
    api = Get.put(ApiClient());
    adapter = _LoginAdapter();
    api.dio.httpClientAdapter = adapter;
    final remote = AuthRemoteDataSource(
      api: api,
      deviceService: deviceService(),
    );
    final repository = AuthRepositoryImpl(remote, session);
    login = Login(repository);
    register = Register(repository);
  });

  tearDown(() {
    api.dio.close();
    Get.reset();
  });

  test(
    'account login sends the curl contract and persists the returned token',
    () async {
      session.token.value = 'previous-session';
      final result = await login(
        const LoginParams(
          account: '  person@example.com  ',
          password: ' password with spaces ',
        ),
      );

      expect(result.failureOrNull, isNull);
      expect(result.isOk, isTrue);
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.toString(), 'https://chat.piisiit.com/api/auth/login');
      expect(request.headers['Accept'], '*/*');
      expect(request.contentType, 'application/json');
      expect(request.headers.containsKey('Authorization'), isFalse);
      final body = request.data as Map<String, dynamic>;
      expect(body.keys.toSet(), {
        'account',
        'password',
        'clientDeviceId',
        'appVersion',
        'deviceName',
        'platform',
        'deviceModel',
      });
      expect(body['account'], 'person@example.com');
      expect(body['password'], ' password with spaces ');
      expect(
        Uuid.isValidUUID(fromString: body['clientDeviceId'] as String),
        isTrue,
      );
      expect(body['appVersion'], '1.0.2');
      expect(body['deviceName'], 'iPhone');
      expect(body['platform'], 'iOS');
      expect(body['deviceModel'], 'iPhone17,1');
      expect(session.token.value, 'test-token');
      expect(
        await const FlutterSecureStorage().read(key: 'token'),
        'test-token',
      );
    },
  );

  test(
    'device UUID survives a new service instance and session logout',
    () async {
      final first = await deviceService().read();
      await session.clearSession();
      final second = await deviceService().read();
      expect(second.clientDeviceId, first.clientDeviceId);
      expect(Uuid.isValidUUID(fromString: second.clientDeviceId), isTrue);
    },
  );

  test('blank account or password fails before making a request', () async {
    for (final params in [
      const LoginParams(account: '  ', password: 'password'),
      const LoginParams(account: 'username', password: ''),
    ]) {
      final result = await login(params);
      expect(result.failureOrNull, isA<ValidationFailure>());
    }
    expect(adapter.requests, isEmpty);
  });

  test('401 shows server error without clearing an existing session', () async {
    session.token.value = 'previous-session';
    adapter.statusCode = 401;
    adapter.body = {'message': 'Invalid account or password'};
    final result = await login(
      const LoginParams(account: 'username', password: 'wrong'),
    );
    expect(result.failureOrNull, isA<UnauthorizedFailure>());
    expect(result.failureOrNull?.message, 'Invalid account or password');
    expect(session.token.value, 'previous-session');
  });

  test(
    'body error code overrides HTTP 200 and never persists a token',
    () async {
      adapter.body = {'code': 400, 'message': 'Account is disabled'};
      final result = await login(
        const LoginParams(account: 'username', password: 'password'),
      );
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(session.token.value, isNull);
    },
  );

  test(
    'HTTP status supports a token response without an envelope code',
    () async {
      adapter.body = {
        'accessToken': 'test-token',
        'user': {'id': '123', 'fullName': 'Test'},
      };
      final result = await login(
        const LoginParams(account: '+85512345678', password: 'password'),
      );
      expect(result.isOk, isTrue);
      expect(session.user.value?.id, '123');
      expect(session.token.value, 'test-token');
    },
  );

  test(
    'registration sends the curl contract and accepts success without a token',
    () async {
      adapter.statusCode = 201;
      adapter.body = {'message': 'Account created'};
      final result = await register(
        const RegisterParams(
          account: '  new.account  ',
          password: ' password with spaces ',
          confirmPassword: ' password with spaces ',
        ),
      );

      expect(result.isOk, isTrue);
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(
        request.uri.toString(),
        'https://chat.piisiit.com/api/auth/register',
      );
      expect(request.headers['Accept'], '*/*');
      expect(request.contentType, 'application/json');
      expect(request.headers.containsKey('Authorization'), isFalse);
      final body = request.data as Map<String, dynamic>;
      expect(body.keys.toSet(), {
        'account',
        'password',
        'clientDeviceId',
        'appVersion',
        'deviceName',
        'platform',
        'deviceModel',
      });
      expect(body['account'], 'new.account');
      expect(body['password'], ' password with spaces ');
      final device = await deviceService().read();
      expect(body['clientDeviceId'], device.clientDeviceId);
      expect(body['appVersion'], '1.0.2');
      expect(body['deviceName'], 'iPhone');
      expect(body['platform'], 'iOS');
      expect(body['deviceModel'], 'iPhone17,1');
      expect(session.token.value, isNull);
    },
  );

  test(
    'registration validates the account and password confirmation',
    () async {
      for (final params in [
        const RegisterParams(
          account: ' ',
          password: 'password',
          confirmPassword: 'password',
        ),
        const RegisterParams(
          account: 'username',
          password: 'password',
          confirmPassword: 'different',
        ),
      ]) {
        final result = await register(params);
        expect(result.failureOrNull, isA<ValidationFailure>());
      }
      expect(adapter.requests, isEmpty);
    },
  );

  test(
    'duplicate account error is returned without altering the session',
    () async {
      session.token.value = 'existing-session';
      adapter.statusCode = 409;
      adapter.body = {'message': 'Account already exists'};
      final result = await register(
        const RegisterParams(
          account: 'existing.account',
          password: 'password',
          confirmPassword: 'password',
        ),
      );
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.message, 'Account already exists');
      expect(session.token.value, 'existing-session');
    },
  );

  test(
    'actual server credential error preserves the PascalCase message',
    () async {
      adapter.statusCode = 500;
      adapter.body = {
        'Success': false,
        'Message': 'Invalid credential!',
        'Data': null,
        'Errors': null,
      };
      final result = await login(
        const LoginParams(account: 'unknown-account', password: 'password'),
      );
      expect(result.failureOrNull?.message, 'Invalid credential!');
      expect(session.token.value, isNull);
    },
  );

  test('registration displays the actual field validation error', () async {
    adapter.statusCode = 400;
    adapter.body = {
      'success': false,
      'message': 'Validation failed',
      'data': null,
      'errors': {
        'Account': ['Account is required'],
      },
    };
    final result = await register(
      const RegisterParams(
        account: 'example',
        password: 'password',
        confirmPassword: 'password',
      ),
    );
    expect(result.failureOrNull?.message, 'Account is required');
  });

  test(
    'a false success flag cannot create a session or report registration success',
    () async {
      for (final key in ['success', 'Success']) {
        adapter.body = {
          key: false,
          'message': 'Account unavailable',
          'data': {'token': 'must-not-be-saved'},
        };
        final loginResult = await login(
          const LoginParams(account: 'example', password: 'password'),
        );
        final registerResult = await register(
          const RegisterParams(
            account: 'example',
            password: 'password',
            confirmPassword: 'password',
          ),
        );
        expect(loginResult.isErr, isTrue);
        expect(registerResult.isErr, isTrue);
        expect(session.token.value, isNull);
      }
    },
  );

  test(
    'PascalCase access tokens from the account server are persisted',
    () async {
      adapter.body = {
        'Success': true,
        'Message': 'OK',
        'Data': {
          'AccessToken': 'test-token',
          'User': {'Id': '123'},
        },
      };
      final result = await login(
        const LoginParams(account: 'example', password: 'password'),
      );
      expect(result.isOk, isTrue);
      expect(session.token.value, 'test-token');
      expect(session.user.value?.id, '123');
    },
  );

  test(
    'missing optional device plugins do not block the login request',
    () async {
      final service = AuthDeviceService(
        storage: storage,
        packageInfo: () async => throw MissingPluginException('package info'),
        deviceInfo: () async => throw MissingPluginException('device info'),
      );
      final repository = AuthRepositoryImpl(
        AuthRemoteDataSource(api: api, deviceService: service),
        session,
      );
      final result = await Login(repository)(
        const LoginParams(account: 'example', password: 'password'),
      );
      expect(result.isOk, isTrue);
      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(
        Uuid.isValidUUID(fromString: body['clientDeviceId'] as String),
        isTrue,
      );
      expect(body['appVersion'], '');
      expect(body['deviceModel'], '');
    },
  );
}

class _LoginAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int statusCode = 200;
  Map<String, dynamic> body = {
    'code': 200,
    'data': {
      'token': 'test-token',
      'user': {'id': '123', 'fullName': 'Test'},
    },
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
