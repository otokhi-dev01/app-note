import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/splash/presentation/controllers/splash_controller.dart';
import 'package:Note/routes/app_pages.dart';

class _Adapter implements dio.HttpClientAdapter {
  final requests = <dio.RequestOptions>[];
  int status = 200;
  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return dio.ResponseBody.fromString(
      '{}',
      status,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory temporary;
  late Map<String, String> stored;
  Completer<void>? pendingRead;
  bool unavailable = false;

  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('session_restore_test_');
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => temporary.path,
    );
    await GetStorage.init();
  });
  tearDownAll(() => temporary.delete(recursive: true));
  setUp(() async {
    Get.testMode = true;
    pendingRead = null;
    unavailable = false;
    await GetStorage().erase();
    stored = {
      'token': 'saved-token',
      'user': jsonEncode({'id': 'saved-user'}),
    };
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = Map<String, dynamic>.from(call.arguments);
      switch (call.method) {
        case 'read':
          if (unavailable) throw PlatformException(code: 'device_locked');
          await pendingRead?.future;
          return stored[args['key']];
        case 'write':
          stored[args['key']] = args['value'];
          return null;
        case 'delete':
          stored.remove(args['key']);
          return null;
        case 'deleteAll':
          stored.clear();
          return null;
      }
      return null;
    });
  });
  tearDown(() {
    Get.reset();
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<SessionStorage> mount(
    WidgetTester tester, {
    bool guest = false,
  }) async {
    final session = Get.put(SessionStorage());
    final mode = Get.put(GuestModeService());
    mode.isGuestMode.value = guest;
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: Routes.SPLASH,
        getPages: [
          GetPage(
            name: Routes.SPLASH,
            binding: BindingsBuilder(() {
              Get.put(SplashController());
            }),
            page: () => const Scaffold(body: Text('Starting')),
          ),
          GetPage(
            name: Routes.FOLDER,
            page: () => const Scaffold(body: Text('Notes')),
          ),
          GetPage(
            name: Routes.ONBOARDING,
            page: () => const Scaffold(body: Text('Welcome')),
          ),
          GetPage(
            name: '/other',
            page: () => const Scaffold(body: Text('Other')),
          ),
          GetPage(
            name: Routes.LOGIN,
            page: () => const Scaffold(body: Text('Sign in')),
          ),
        ],
      ),
    );
    await tester.pump();
    return session;
  }

  testWidgets(
    'Slow secure restore waits past splash delay and authenticates first request',
    (tester) async {
      pendingRead = Completer<void>();
      final session = await mount(tester, guest: true);
      final api = Get.put(ApiClient());
      final adapter = _Adapter();
      api.dio.httpClientAdapter = adapter;
      final request = api.dio.get('/api/folder');
      await tester.pump(const Duration(seconds: 8));
      expect(Get.currentRoute, Routes.SPLASH);
      expect(adapter.requests, isEmpty);
      pendingRead!.complete();
      await tester.pumpAndSettle();
      await request;
      expect(Get.currentRoute, Routes.FOLDER);
      expect(session.user.value?.id, 'saved-user');
      expect(session.token.value, 'saved-token');
      expect(Get.find<GuestModeService>().isGuestMode.value, isFalse);
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer saved-token',
      );
    },
  );

  testWidgets(
    'Unavailable Keychain keeps session on disk and retries without login',
    (tester) async {
      unavailable = true;
      final session = await mount(tester);
      await tester.pump(const Duration(seconds: 4));
      expect(Get.currentRoute, Routes.SPLASH);
      expect(Get.find<SplashController>().restoreFailed.value, isTrue);
      expect(stored['token'], 'saved-token');
      unavailable = false;
      await Get.find<SplashController>().retryRestore();
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.FOLDER);
      expect(session.isLoggedIn, isTrue);
    },
  );

  testWidgets('Fresh install still opens onboarding', (tester) async {
    stored.clear();
    await mount(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.ONBOARDING);
  });

  testWidgets('Guest choice still survives restart', (tester) async {
    stored.clear();
    await mount(tester, guest: true);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.FOLDER);
    expect(Get.find<GuestModeService>().isGuestMode.value, isTrue);
  });

  testWidgets(
    'Disposed splash does not navigate after delayed storage completes',
    (tester) async {
      pendingRead = Completer<void>();
      await mount(tester);
      unawaited(Get.offAllNamed('/other'));
      await tester.pumpAndSettle();
      pendingRead!.complete();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/other');
      expect(tester.takeException(), isNull);
    },
  );

  test('Unauthenticated 401 never deletes an unrestored session', () async {
    unavailable = true;
    final session = Get.put(SessionStorage());
    await session.ready;
    final api = Get.put(ApiClient());
    api.dio.httpClientAdapter = _Adapter()..status = 401;
    await expectLater(
      api.dio.get('/api/folder'),
      throwsA(isA<dio.DioException>()),
    );
    expect(stored['token'], 'saved-token');
    expect(stored['user'], isNotNull);
    unavailable = false;
    await session.loadSession();
    expect(session.isLoggedIn, isTrue);
  });

  test(
    'Restore repairs a legacy prefixed token without changing other keys',
    () async {
      stored['token'] = ' \tBearer bearer saved-token\n';
      stored['encryption_key'] = 'local-key';
      final before = Map<String, String>.from(stored)
        ..['token'] = 'saved-token';
      final session = Get.put(SessionStorage());
      await session.ready;
      expect(session.token.value, 'saved-token');
      expect(stored, before);
      final restarted = SessionStorage();
      await restarted.ready;
      expect(restarted.token.value, 'saved-token');
    },
  );

  testWidgets(
    'Concurrent terminal 401s remove only token and navigate to login',
    (tester) async {
      stored['refresh_token'] = 'retained-refresh';
      stored['encryption_key'] = 'local-key';
      stored['identity_record'] = 'saved-identity';
      await GetStorage().write('notes', ['offline-note']);
      await GetStorage().write('theme', 'dark');
      final before = Map<String, String>.from(stored)..remove('token');
      final session = await mount(tester);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.FOLDER);
      final api = Get.put(ApiClient(refreshTokenEndpoint: null));
      final adapter = _Adapter()..status = 401;
      api.dio.httpClientAdapter = adapter;
      final requests = [
        for (final path in ['/api/note', '/api/folder'])
          expectLater(api.dio.get(path), throwsA(isA<dio.DioException>())),
      ];
      await tester.pumpAndSettle();
      await Future.wait(requests);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.LOGIN);
      expect(session.isLoggedIn, isFalse);
      expect(stored, before);
      expect(GetStorage().read('notes'), ['offline-note']);
      expect(GetStorage().read('theme'), 'dark');
      expect(adapter.requests, hasLength(2));
      final restarted = SessionStorage();
      await restarted.ready;
      expect(restarted.isLoggedIn, isFalse);
      expect(restarted.refreshToken.value, isNull);
      expect(restarted.user.value, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
