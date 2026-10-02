import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';
import 'package:Note/features/auth/data/services/registration_service.dart';
import 'package:Note/features/auth/presentation/controllers/registration_controller.dart';
import 'package:Note/features/auth/presentation/views/register_view.dart';
import 'package:Note/routes/app_pages.dart';

class _Session extends SessionStorage {
  @override
  Future<void> loadSession() async {}
}

const _deviceInfo = AuthDeviceInfo(
  clientDeviceId: 'fdffb4d7-e037-489f-aa84-a0ea82c138fe',
  deviceName: 'Test device',
  platform: 'iOS',
  deviceModel: 'Test model',
  appVersion: '1.0.1',
);

class _Device implements AuthDeviceService {
  Future<AuthDeviceInfo> Function() respond = () async => _deviceInfo;
  @override
  Future<AuthDeviceInfo> read() => respond();
}

class _Adapter implements dio.HttpClientAdapter {
  final requests = <dio.RequestOptions>[];
  FutureOr<dio.ResponseBody> Function(dio.RequestOptions) respond = (_) =>
      _json({'success': true});
  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

dio.ResponseBody _json(Object body, [int status = 200]) =>
    dio.ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Adapter adapter;
  late _Device device;
  late RegistrationService service;
  late RegistrationController controller;
  late SessionStorage session;
  late DateTime now;

  setUp(() {
    Get.testMode = true;
    now = DateTime.utc(2026, 10, 2);
    session = Get.put<SessionStorage>(_Session());
    final api = Get.put(ApiClient());
    adapter = _Adapter();
    api.dio.httpClientAdapter = adapter;
    device = _Device();
    service = RegistrationService(api, deviceService: device);
    controller = RegistrationController(service, now: () => now);
  });
  tearDown(() {
    if (!controller.isClosed) controller.onDelete();
    Get.reset();
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        initialRoute: Routes.REGISTER,
        getPages: [
          GetPage(
            name: Routes.REGISTER,
            page: () => const RegisterScreen(),
            binding: BindingsBuilder(() => Get.lazyPut(() => controller)),
          ),
          GetPage(
            name: Routes.LOGIN,
            page: () => const Scaffold(body: Text('Login destination')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  void fill() {
    controller.emailController.text = ' new@example.com ';
    controller.passwordController.text = ' test-password ';
    controller.confirmPasswordController.text = ' test-password ';
  }

  Future<void> finish(WidgetTester tester, Future<void> operation) async {
    await tester.pumpAndSettle();
    await operation;
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    if (!controller.isClosed) controller.onDelete();
    Get.reset();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Registration validates email, password and confirmation locally',
    (tester) async {
      await mount(tester);
      expect(find.byType(EditableText), findsNWidgets(3));
      await finish(tester, controller.register());
      expect(controller.error.value, contains('email'));
      fill();
      controller.emailController.text = 'invalid';
      await finish(tester, controller.register());
      expect(controller.error.value, contains('email'));
      fill();
      controller.passwordController.text = '123';
      await finish(tester, controller.register());
      expect(controller.error.value, isNotEmpty);
      fill();
      controller.confirmPasswordController.clear();
      await finish(tester, controller.register());
      expect(controller.error.value, contains('confirm'));
      fill();
      controller.confirmPasswordController.text = 'different';
      await finish(tester, controller.register());
      expect(controller.error.value, 'Passwords do not match.');
      expect(adapter.requests, isEmpty);
      await dispose(tester);
    },
  );

  testWidgets(
    'Registration posts exact Swagger fields then clears forms and returns to login',
    (tester) async {
      await mount(tester);
      fill();
      adapter.respond = (_) => _json({
        'success': true,
        'data': {'accessToken': 'must-not-be-stored'},
      });
      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(
        request.uri.toString(),
        'https://chat.piisiit.com/api/auth/register',
      );
      expect(request.data, {
        'account': 'new@example.com',
        'password': ' test-password ',
        'clientDeviceId': _deviceInfo.clientDeviceId,
        'deviceName': 'Test device',
        'platform': 'iOS',
        'deviceModel': 'Test model',
        'appVersion': '1.0.1',
      });
      expect(request.extra['requiresAuth'], isFalse);
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(find.text('Login destination'), findsOneWidget);
      expect(
        find.text('Account created successfully! Please log in.'),
        findsOneWidget,
      );
      expect(find.byType(RegisterScreen), findsNothing);
      expect(controller.completed.value, isTrue);
      expect(controller.emailController.text, isEmpty);
      expect(controller.passwordController.text, isEmpty);
      expect(controller.confirmPasswordController.text, isEmpty);
      expect(session.isLoggedIn, isFalse);
      await controller.register();
      expect(adapter.requests, hasLength(1));
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets('Registration failure keeps fields and retry succeeds', (
    tester,
  ) async {
    await mount(tester);
    fill();
    adapter.respond = (_) =>
        _json({'success': false, 'message': 'Email already registered'}, 409);
    await finish(tester, controller.register());
    expect(controller.error.value, 'Email already registered');
    expect(controller.passwordController.text, ' test-password ');
    expect(controller.completed.value, isFalse);
    expect(controller.isLoading.value, isFalse);
    adapter.respond = (_) => _json({'Code': 201, 'Message': 'Account created'});
    await finish(tester, controller.register());
    expect(find.text('Login destination'), findsOneWidget);
    expect(adapter.requests, hasLength(2));
    await dispose(tester);
  });

  testWidgets(
    'Registration prevents duplicate requests while device or server responds',
    (tester) async {
      await mount(tester);
      fill();
      final devicePending = Completer<AuthDeviceInfo>();
      final responsePending = Completer<dio.ResponseBody>();
      device.respond = () => devicePending.future;
      adapter.respond = (_) => responsePending.future;
      final first = controller.register();
      await controller.register();
      expect(controller.isLoading.value, isTrue);
      expect(adapter.requests, isEmpty);
      devicePending.complete(_deviceInfo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await controller.register();
      expect(adapter.requests, hasLength(1));
      responsePending.complete(_json({'success': true}));
      await finish(tester, first);
      expect(find.text('Login destination'), findsOneWidget);
      await dispose(tester);
    },
  );

  testWidgets(
    'Registration rate limit blocks retries and refreshes on resume',
    (tester) async {
      await mount(tester);
      fill();
      adapter.respond = (_) => dio.ResponseBody.fromString(
        '{"success":false}',
        429,
        headers: {
          dio.Headers.contentTypeHeader: ['application/json'],
          'retry-after': ['90'],
        },
      );
      await finish(tester, controller.register());
      expect(controller.retryIn.value, 90);
      await finish(tester, controller.register());
      expect(adapter.requests, hasLength(1));
      now = now.add(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Try again in 60 seconds'), findsOneWidget);
      now = now.add(const Duration(seconds: 60));
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.retryIn.value, 0);
      adapter.respond = (_) => _json({'success': true});
      await finish(tester, controller.register());
      expect(find.text('Login destination'), findsOneWidget);
      await dispose(tester);
    },
  );

  testWidgets('Registration ignores late completion after the user leaves', (
    tester,
  ) async {
    await mount(tester);
    fill();
    final pending = Completer<dio.ResponseBody>();
    adapter.respond = (_) => pending.future;
    final first = controller.register();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    unawaited(Get.offAllNamed(Routes.LOGIN));
    await tester.pumpAndSettle();
    pending.complete(_json({'success': true}));
    await finish(tester, first);
    expect(controller.isClosed, isTrue);
    expect(controller.completed.value, isFalse);
    expect(
      find.text('Account created successfully! Please log in.'),
      findsNothing,
    );
    await dispose(tester);
  });

  testWidgets(
    'Leaving during device lookup prevents any registration request',
    (tester) async {
      await mount(tester);
      fill();
      final pending = Completer<AuthDeviceInfo>();
      device.respond = () => pending.future;
      final first = controller.register();
      unawaited(Get.offAllNamed(Routes.LOGIN));
      await tester.pumpAndSettle();
      pending.complete(_deviceInfo);
      await finish(tester, first);
      expect(adapter.requests, isEmpty);
      expect(controller.completed.value, isFalse);
      await dispose(tester);
    },
  );

  test(
    'Registration rejects HTTP-200 failures and malformed responses',
    () async {
      for (final body in [
        {'success': false, 'message': 'Rejected'},
        {'Success': false, 'Code': 200, 'Message': 'Rejected'},
        {'code': 400, 'message': 'Rejected'},
        {
          'errors': {
            'account': ['Invalid account'],
          },
        },
        <String, dynamic>{},
        '<html>Server error</html>',
      ]) {
        adapter.respond = (_) => _json(body);
        await expectLater(
          service.register(
            account: 'new@example.com',
            password: 'test-password',
          ),
          throwsA(isA<RegistrationException>()),
        );
      }
      expect(session.isLoggedIn, isFalse);
    },
  );

  test(
    'Registration remains public and preserves an existing session on rejection',
    () async {
      session.token.value = 'existing-session';
      adapter.respond = (_) =>
          _json({'success': false, 'message': 'Rejected'}, 401);
      await expectLater(
        service.register(account: 'new@example.com', password: 'test-password'),
        throwsA(isA<RegistrationException>()),
      );
      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
      expect(session.token.value, 'existing-session');
    },
  );

  test(
    'Registration transport logs never include passwords or response tokens',
    () async {
      final output = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) output.add(message);
      };
      try {
        adapter.respond = (_) => _json({
          'success': true,
          'data': {'accessToken': 'private-response-token'},
        });
        await service.register(
          account: 'new@example.com',
          password: 'private-request-password',
        );
        expect(output.join('\n'), isNot(contains('private-request-password')));
        expect(output.join('\n'), isNot(contains('private-response-token')));
      } finally {
        debugPrint = original;
      }
    },
  );
}
