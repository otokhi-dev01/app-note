import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/data/services/registration_service.dart';
import 'package:Note/features/auth/presentation/controllers/registration_controller.dart';
import 'package:Note/features/auth/presentation/views/register_view.dart';
import 'package:Note/features/auth/presentation/widgets/account_input_field.dart';
import 'package:Note/features/auth/presentation/widgets/registration_success.dart';
import 'package:Note/routes/app_pages.dart';

class _Session extends SessionStorage {
  @override
  Future<void> loadSession() async {}

  @override
  Future<void> saveSession(
    String token,
    UserData userData, {
    String? refreshToken,
  }) async {
    this.token.value = token;
    user.value = userData;
  }
}

class _NavigationObserver extends NavigatorObserver {
  final pushed = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route.settings.name);
  }
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
      _json({
        'success': true,
        'data': {'accessToken': 'signup-token'},
      });
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
  late _NavigationObserver navigation;

  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({});
    navigation = _NavigationObserver();
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
        navigatorObservers: [navigation],
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
          GetPage(
            name: Routes.FOLDER,
            page: () => const Scaffold(body: Text('App destination')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  void fill() {
    controller.accountController.text = ' new@example.com ';
    controller.passwordController.text = ' test-password ';
    controller.confirmPasswordController.text = ' test-password ';
  }

  Future<void> finish(WidgetTester tester, Future<void> operation) async {
    await tester.pumpAndSettle();
    await operation;
  }

  Future<void> continueFromSuccess(
    WidgetTester tester, {
    bool emailVerified = false,
  }) async {
    expect(find.byType(RegistrationSuccess), findsOneWidget);
    expect(
      find.text(
        emailVerified
            ? 'Email successfully verified'
            : 'Account created successfully',
      ),
      findsOneWidget,
    );
    expect(find.text('App destination'), findsNothing);
    expect(session.isLoggedIn, isTrue);
    unawaited(tester.binding.reassembleApplication());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(RegistrationSuccess), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(RegistrationSuccess), findsNothing);
    expect(find.text('App destination'), findsOneWidget);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    if (!controller.isClosed) controller.onDelete();
    Get.reset();
    await tester.pumpAndSettle();
  }

  Future<void> sendCode(WidgetTester tester, {String? account}) async {
    fill();
    controller.accountController.text = account ?? 'new@example.com';
    await finish(tester, controller.register());
    if (controller.isEmailStep.value) {
      controller.emailController.text = 'new@example.com';
      await finish(tester, controller.register());
    }
    expect(controller.isOtpStep.value, isTrue);
    expect(controller.completed.value, isFalse);
  }

  for (final input in [
    'newuser',
    'name text',
    'Nona11',
    'សុខ ដារ៉ា',
    '012345678',
  ]) {
    testWidgets(
      'Username or phone $input skips email verification and registers directly',
      (tester) async {
        await mount(tester);
        fill();
        controller.accountController.text = input;
        await tester.pump();
        expect(find.byType(AccountInputField), findsOneWidget);
        expect(find.byType(EditableText), findsNWidgets(3));
        final isPhone = controller.accountController.isPhoneInput;
        final account = controller.accountController.account;
        expect(
          find.byKey(const ValueKey('account-country-picker')),
          isPhone ? findsOneWidget : findsNothing,
        );
        await finish(tester, controller.register());
        expect(controller.isEmailStep.value, isFalse);
        expect(controller.isOtpStep.value, isFalse);
        expect(adapter.requests.map((r) => r.uri.path).toList(), [
          '/api/auth/register',
          if (isPhone) '/api/users/profile/save',
        ]);
        expect(adapter.requests[0].data['account'], account);
        if (isPhone) {
          expect(adapter.requests[1].data, {
            'email': '855012345678@piisiit.com',
            'phone': '+855012345678',
          });
        }
        await continueFromSuccess(tester);
        expect(controller.passwordController.text, isEmpty);
        expect(find.text('App destination'), findsOneWidget);
        unawaited(tester.binding.reassembleApplication());
        await tester.pumpAndSettle();
        expect(Get.currentRoute, Routes.FOLDER);
        expect(find.byType(RegisterScreen), findsNothing);
        expect(Get.key.currentState!.canPop(), isFalse);
        expect(controller.isClosed, isTrue);
        expect(
          navigation.pushed.where((route) => route == Routes.FOLDER),
          hasLength(1),
        );
        expect(Get.arguments, isNull);
        expect(adapter.requests, hasLength(isPhone ? 2 : 1));
        expect(session.isLoggedIn, isTrue);
        await dispose(tester);
      },
    );
  }

  testWidgets(
    'Back from email verification returns to the original account input',
    (tester) async {
      await mount(tester);
      fill();
      controller.accountController.text = 'new@example.com';
      await finish(tester, controller.register());
      expect(controller.isOtpStep.value, isTrue);
      await tester.ensureVisible(find.text('Edit Details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Details'));
      await tester.pumpAndSettle();
      expect(controller.isOtpStep.value, isFalse);
      expect(controller.accountController.text, 'new@example.com');
      expect(find.byType(AccountInputField), findsOneWidget);
      expect(adapter.requests, hasLength(1));
      await dispose(tester);
    },
  );

  testWidgets('Username symbols are rejected before any registration request', (
    tester,
  ) async {
    await mount(tester);
    for (final username in [
      'name!',
      'name_text',
      'name.text',
      'name/text',
      'name#1',
      'name🙂',
      'name\ntext',
    ]) {
      fill();
      controller.accountController.text = username;
      await finish(tester, controller.register());
      expect(controller.error.value, 'register_username_invalid'.tr);
      expect(adapter.requests, isEmpty);
      expect(controller.completed.value, isFalse);
    }
    await dispose(tester);
  });

  testWidgets('Username without a token uses temporary login for the app', (
    tester,
  ) async {
    await mount(tester);
    fill();
    controller.accountController.text = 'name text';
    adapter.respond = (request) => request.uri.path.endsWith('/register')
        ? _json({'success': true})
        : _json({
            'success': true,
            'data': {'accessToken': 'temporary-token'},
          });
    await finish(tester, controller.register());
    expect(adapter.requests, hasLength(2));
    expect(find.byType(RegistrationSuccess), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('App destination'), findsOneWidget);
    expect(Get.arguments, isNull);
    expect(session.isLoggedIn, isTrue);
    await dispose(tester);
  });

  testWidgets(
    'Successful signup opens the app once despite repeated completion',
    (tester) async {
      await mount(tester);
      fill();
      controller.accountController.text = 'name text';
      await finish(tester, controller.register());
      await tester.tap(find.text('Done'));
      controller.finishRegistration();
      await tester.pumpAndSettle();
      expect(find.text('App destination'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('App destination'), findsOneWidget);
      expect(Get.arguments, isNull);
      expect(
        navigation.pushed.where((route) => route == Routes.FOLDER),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets('Unconfirmed registration cannot show success or open the app', (
    tester,
  ) async {
    await mount(tester);
    fill();
    controller.accountController.text = 'name text';
    adapter.respond = (_) => _json({'message': 'Account could not be created'});
    await finish(tester, controller.register());
    expect(controller.completed.value, isFalse);
    expect(find.byType(RegistrationSuccess), findsNothing);
    expect(find.text('App destination'), findsNothing);
    expect(controller.error.value, 'Account could not be created');
    controller.finishRegistration();
    await tester.pumpAndSettle();
    expect(find.text('App destination'), findsNothing);
    await dispose(tester);
  });

  testWidgets('Signup validates username, email, phone and passwords locally', (
    tester,
  ) async {
    await mount(tester);
    expect(find.byType(EditableText), findsNWidgets(3));
    await finish(tester, controller.register());
    expect(controller.error.value, contains('username'));
    fill();
    controller.accountController.text = 'invalid@';
    await finish(tester, controller.register());
    expect(controller.error.value, contains('email'));
    fill();
    controller.accountController.text = '123';
    await finish(tester, controller.register());
    expect(controller.error.value, contains('phone'));
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
  });

  testWidgets(
    'Signup sends and verifies email OTP before creating and saving profile',
    (tester) async {
      await mount(tester);
      fill();
      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.uri.toString(),
        'https://chat.piisiit.com/api/auth/signup/send-otp',
      );
      expect(adapter.requests.single.data, {'email': 'new@example.com'});
      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.byType(EditableText), findsOneWidget);
      expect(controller.resendIn.value, 60);
      expect(session.isLoggedIn, isFalse);

      await tester.enterText(find.byType(EditableText), '012345');
      await tester.ensureVisible(find.text('Verify & Create Account'));
      await tester.tap(find.text('Verify & Create Account'));
      await tester.pumpAndSettle();
      expect(adapter.requests.map((r) => r.uri.path).toList(), [
        '/api/auth/signup/send-otp',
        '/api/auth/verify-otp/email',
        '/api/auth/register',
        '/api/users/profile/save',
      ]);
      expect(adapter.requests[1].data, {
        'email': 'new@example.com',
        'otp': '012345',
      });
      expect(adapter.requests[2].data, {
        'account': 'new@example.com',
        'password': ' test-password ',
        'clientDeviceId': _deviceInfo.clientDeviceId,
        'deviceName': 'Test device',
        'platform': 'iOS',
        'deviceModel': 'Test model',
        'appVersion': '1.0.1',
      });
      expect(adapter.requests[3].data, {'email': 'new@example.com'});
      for (final request in adapter.requests.take(3)) {
        expect(request.extra['requiresAuth'], isFalse);
        expect(request.headers.containsKey('Authorization'), isFalse);
      }
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer signup-token',
      );
      expect(find.byType(RegistrationSuccess), findsOneWidget);
      expect(find.text('App destination'), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      expect(controller.completed.value, isTrue);
      for (final field in [
        controller.accountController,
        controller.emailController,
        controller.passwordController,
        controller.confirmPasswordController,
        controller.otpController,
      ]) {
        expect(field.text, isEmpty);
      }
      expect(session.isLoggedIn, isTrue);
      await controller.register();
      expect(adapter.requests, hasLength(4));
      await continueFromSuccess(tester, emailVerified: true);
      expect(find.text('App destination'), findsOneWidget);
      expect(find.text('Email successfully verified'), findsNothing);
      expect(Get.arguments, isNull);
      expect(Get.key.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets(
    'OTP input accepts only six digits and preserves a leading zero',
    (tester) async {
      await mount(tester);
      await sendCode(tester);
      await tester.enterText(find.byType(EditableText), '01a234567');
      expect(controller.otpController.text, '012345');
      controller.otpController.text = '12345';
      await finish(tester, controller.verifyAndRegister());
      expect(controller.error.value, contains('6-digit'));
      controller.otpController.text = 'abcdef';
      await finish(tester, controller.verifyAndRegister());
      expect(adapter.requests, hasLength(1));
      await dispose(tester);
    },
  );

  testWidgets(
    'Invalid or expired OTP keeps the verification screen and prevents registration',
    (tester) async {
      await mount(tester);
      await sendCode(tester);
      adapter.respond = (_) =>
          _json({'success': false, 'message': 'Code expired'});
      controller.otpController.text = '123456';
      await finish(tester, controller.verifyAndRegister());
      expect(controller.error.value, 'Code expired');
      expect(controller.isOtpStep.value, isTrue);
      expect(controller.accountCreated.value, isFalse);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.uri.path, '/api/auth/verify-otp/email');
      await dispose(tester);
    },
  );

  testWidgets('Resend waits for cooldown and refreshes on resume', (
    tester,
  ) async {
    await mount(tester);
    await sendCode(tester);
    controller.otpController.text = '123456';
    await finish(tester, controller.resendOtp());
    expect(adapter.requests, hasLength(1));
    now = now.add(const Duration(seconds: 30));
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Resend code in 30 seconds'), findsOneWidget);
    now = now.add(const Duration(seconds: 30));
    await finish(tester, controller.resendOtp());
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.data, {'email': 'new@example.com'});
    expect(controller.resendIn.value, 60);
    expect(controller.otpController.text, isEmpty);
    await dispose(tester);
  });

  testWidgets(
    'Editing email resets verification and sends a code for the new address',
    (tester) async {
      await mount(tester);
      await sendCode(tester);
      controller.otpController.text = '123456';
      controller.editDetails();
      controller.accountController.text = 'other@gmail.com';
      await finish(tester, controller.register());
      expect(controller.verificationEmail.value, 'other@gmail.com');
      expect(controller.otpController.text, isEmpty);
      expect(adapter.requests.last.data, {'email': 'other@gmail.com'});
      await dispose(tester);
    },
  );

  testWidgets(
    'Sending failure preserves details and a retry opens verification',
    (tester) async {
      await mount(tester);
      fill();
      adapter.respond = (_) =>
          _json({'success': false, 'message': 'Email unavailable'}, 409);
      await finish(tester, controller.register());
      expect(controller.error.value, 'Email unavailable');
      expect(controller.isOtpStep.value, isFalse);
      expect(controller.passwordController.text, ' test-password ');
      adapter.respond = (_) => _json({'success': true});
      await finish(tester, controller.register());
      expect(controller.isOtpStep.value, isTrue);
      expect(adapter.requests, hasLength(2));
      await dispose(tester);
    },
  );

  testWidgets(
    'OTP verification and account creation retries do not consume the same code twice',
    (tester) async {
      await mount(tester);
      await sendCode(tester);
      var registerAttempts = 0;
      adapter.respond = (request) {
        if (request.uri.path.endsWith('/register') && registerAttempts++ == 0) {
          return _json({'success': false, 'message': 'Try again'}, 503);
        }
        return _json({
          'success': true,
          'data': {'token': 'signup-token'},
        });
      };
      controller.otpController.text = '123456';
      await finish(tester, controller.verifyAndRegister());
      expect(controller.accountCreated.value, isFalse);
      await finish(tester, controller.verifyAndRegister());
      expect(
        adapter.requests.where((r) => r.uri.path.endsWith('/verify-otp/email')),
        hasLength(1),
      );
      expect(
        adapter.requests.where((r) => r.uri.path.endsWith('/register')),
        hasLength(2),
      );
      await continueFromSuccess(tester, emailVerified: true);
      expect(find.text('App destination'), findsOneWidget);
      await dispose(tester);
    },
  );

  testWidgets(
    'Profile failure permits correction without recreating the account',
    (tester) async {
      await mount(tester);
      await sendCode(tester, account: 'new@example.com');
      adapter.respond = (request) => request.uri.path.endsWith('/profile/save')
          ? _json({'success': false, 'message': 'Profile failed'}, 409)
          : _json({
              'success': true,
              'data': {'token': 'signup-token'},
            });
      controller.otpController.text = '123456';
      await finish(tester, controller.verifyAndRegister());
      expect(controller.accountCreated.value, isTrue);
      expect(controller.completed.value, isFalse);
      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('Email successfully verified'), findsNothing);
      expect(controller.error.value, 'Profile failed');
      adapter.respond = (_) => _json({
        'success': true,
        'data': {'token': 'retry-token'},
      });
      await finish(tester, controller.verifyAndRegister());
      expect(adapter.requests.last.data['email'], 'new@example.com');
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer retry-token',
      );
      expect(
        adapter.requests.where((r) => r.uri.path.endsWith('/register')),
        hasLength(1),
      );
      expect(
        adapter.requests.where((r) => r.uri.path.endsWith('/verify-otp/email')),
        hasLength(1),
      );
      await continueFromSuccess(tester, emailVerified: true);
      expect(find.text('App destination'), findsOneWidget);
      expect(Get.key.currentState!.canPop(), isFalse);
      expect(session.isLoggedIn, isTrue);
      await dispose(tester);
    },
  );

  for (final account in ['new@example.com']) {
    testWidgets(
      'Tokenless signup for $account uses the original account for temporary login',
      (tester) async {
        await mount(tester);
        await sendCode(tester, account: account);
        adapter.respond = (request) => _json({
          'success': true,
          if (request.uri.path.endsWith('/login'))
            'data': {'token': 'temporary-token'},
        });
        controller.otpController.text = '123456';
        await finish(tester, controller.verifyAndRegister());
        expect(adapter.requests.map((r) => r.uri.path).toList(), [
          '/api/auth/signup/send-otp',
          '/api/auth/verify-otp/email',
          '/api/auth/register',
          '/api/auth/login',
          '/api/users/profile/save',
        ]);
        expect(
          adapter.requests.last.headers['Authorization'],
          'Bearer temporary-token',
        );
        expect(adapter.requests[3].data['account'], account);
        expect(session.isLoggedIn, isTrue);
        await continueFromSuccess(tester, emailVerified: true);
        expect(find.text('App destination'), findsOneWidget);
        await dispose(tester);
      },
    );
  }

  for (final locale in [const Locale('en', 'US'), const Locale('km', 'KH')]) {
    for (final emailVerified in [true, false]) {
      testWidgets(
        'Success fits compact dark screens with large text in $locale (email: $emailVerified)',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var done = false;
          await tester.pumpWidget(
            GetMaterialApp(
              translations: AppTranslations(),
              locale: locale,
              theme: ThemeData.dark(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: SafeArea(
                  child: RegistrationSuccess(
                    onDone: () => done = true,
                    emailVerified: emailVerified,
                    account: 'name text',
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.text(
              (emailVerified
                      ? 'register_verified_title'
                      : 'register_created_title')
                  .tr,
            ),
            findsOneWidget,
          );
          await tester.tap(find.text('done_action'.tr));
          await tester.pumpAndSettle();
          expect(done, isTrue);
          await dispose(tester);
        },
      );
    }
  }

  testWidgets('Rate limit blocks sends and refreshes on resume', (
    tester,
  ) async {
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
    now = now.add(const Duration(seconds: 90));
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(controller.retryIn.value, 0);
    adapter.respond = (_) => _json({'success': true});
    await finish(tester, controller.register());
    expect(controller.isOtpStep.value, isTrue);
    await dispose(tester);
  });

  testWidgets('Duplicate submits are locked while the server responds', (
    tester,
  ) async {
    await mount(tester);
    fill();
    final pending = Completer<dio.ResponseBody>();
    adapter.respond = (_) => pending.future;
    final first = controller.register();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await controller.register();
    expect(controller.isLoading.value, isTrue);
    expect(adapter.requests, hasLength(1));
    pending.complete(_json({'success': true}));
    await finish(tester, first);
    expect(controller.isOtpStep.value, isTrue);
    await dispose(tester);
  });

  testWidgets(
    'Leaving during device lookup prevents registration after verification',
    (tester) async {
      await mount(tester);
      await sendCode(tester);
      final pending = Completer<AuthDeviceInfo>();
      device.respond = () => pending.future;
      controller.otpController.text = '123456';
      final first = controller.verifyAndRegister();
      await tester.pump();
      unawaited(Get.offAllNamed(Routes.LOGIN));
      await tester.pumpAndSettle();
      pending.complete(_deviceInfo);
      await finish(tester, first);
      expect(
        adapter.requests.where((r) => r.uri.path.endsWith('/register')),
        isEmpty,
      );
      expect(controller.completed.value, isFalse);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  test(
    'Signup endpoints reject HTTP-200 failures and malformed OTP responses',
    () async {
      for (final body in [
        {'success': false, 'message': 'Rejected'},
        {'Success': false, 'Code': 200, 'Message': 'Rejected'},
        {'code': 400, 'message': 'Rejected'},
        {'message': 'Account could not be created'},
        {'data': null},
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
        await expectLater(
          service.sendOtp(email: 'new@example.com'),
          throwsA(isA<RegistrationException>()),
        );
        await expectLater(
          service.verifyEmailOtp(email: 'new@example.com', otp: '123456'),
          throwsA(isA<RegistrationException>()),
        );
      }
      expect(session.isLoggedIn, isFalse);
    },
  );

  test(
    'Public signup calls preserve an existing session on rejection',
    () async {
      session.token.value = 'existing-session';
      adapter.respond = (_) =>
          _json({'success': false, 'message': 'Rejected'}, 401);
      for (final action in [
        () => service.sendOtp(email: 'new@example.com'),
        () => service.verifyEmailOtp(email: 'new@example.com', otp: '123456'),
        () => service.register(
          account: 'new@example.com',
          password: 'test-password',
        ),
        () => service.saveProfile(
          token: 'signup-token',
          username: 'user',
          email: 'new@example.com',
          phone: '+85512345678',
        ),
      ]) {
        await expectLater(action(), throwsA(isA<RegistrationException>()));
      }
      expect(adapter.requests, hasLength(4));
      for (final request in adapter.requests.take(3)) {
        expect(request.headers.containsKey('Authorization'), isFalse);
      }
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer signup-token',
      );
      expect(session.token.value, 'existing-session');
    },
  );

  test(
    'Signup transport logs exclude passwords, OTPs and temporary tokens',
    () async {
      final output = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) output.add(message);
      };
      try {
        await service.register(
          account: 'new@example.com',
          password: 'private-password',
        );
        await service.verifyEmailOtp(email: 'new@example.com', otp: '987654');
        await service.saveProfile(
          token: 'private-profile-token',
          username: 'user',
          email: 'new@example.com',
          phone: '+85512345678',
        );
        for (final secret in [
          'private-password',
          '987654',
          'private-profile-token',
          'signup-token',
        ]) {
          expect(output.join('\n'), isNot(contains(secret)));
        }
      } finally {
        debugPrint = original;
      }
    },
  );
}
