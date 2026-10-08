import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:Note/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';
import 'package:Note/features/auth/data/services/registration_service.dart';
import 'package:Note/features/auth/presentation/widgets/registration_success.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/data/services/google_sign_in_service.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';
import 'package:Note/features/auth/domain/repositories/auth_repository.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/auth/presentation/controllers/auth_controller.dart';
import 'package:Note/features/auth/presentation/controllers/registration_controller.dart';
import 'package:Note/features/auth/presentation/views/login_view.dart';
import 'package:Note/features/auth/presentation/views/register_view.dart';
import 'package:Note/routes/app_pages.dart';

class _FakeLogin extends Login {
  _FakeLogin(this.result) : super(_NoopRepo());
  final Result<AuthSession> result;
  LoginParams? received;

  @override
  Future<Result<AuthSession>> call(LoginParams params) async {
    received = params;
    return result;
  }
}

class _FakeRegister extends Register {
  _FakeRegister(this.result) : super(_NoopRepo());
  final Result<void> result;
  RegisterParams? received;

  @override
  Future<Result<void>> call(RegisterParams params) async {
    received = params;
    return result;
  }
}

class _PendingLogin extends Login {
  _PendingLogin() : super(_NoopRepo());
  final result = Completer<Result<AuthSession>>();

  @override
  Future<Result<AuthSession>> call(LoginParams params) => result.future;
}

class _FakeGoogleSignIn extends GoogleSignInService {
  _FakeGoogleSignIn(this.result);
  final Future<String?> Function() result;
  int calls = 0;
  @override
  Future<String?> signInIdToken() {
    calls++;
    return result();
  }
}

class _FakeGoogleLogin extends GoogleLogin {
  _FakeGoogleLogin(this.result) : super(_NoopRepo());
  final Result<AuthSession> result;
  final received = <String>[];
  @override
  Future<Result<AuthSession>> call(String token) async {
    received.add(token);
    return result;
  }
}

class _NoopRepo implements AuthRepository {
  const _NoopRepo();
  @override
  noSuchMethod(Invocation invocation) =>
      Future.value(const Err(ValidationFailure('unused')));
}

class _RejectedSessionAdapter implements dio.HttpClientAdapter {
  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => dio.ResponseBody.fromString(
    '{}',
    401,
    headers: {
      dio.Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

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

class _SignupLoginAdapter implements dio.HttpClientAdapter {
  final requests = <dio.RequestOptions>[];

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return dio.ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'accessToken': options.uri.path.endsWith('/register')
              ? 'signup-token'
              : 'signin-token',
          'user': {'id': 'new-user'},
        },
      }),
      200,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp.createTemp('auth_flow_test_');
    addTearDown(() => tempDir.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
    await GetStorage.init();
  });
  Future<void> initialize() async {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({});
    InitialBinding().dependencies();
    await Get.find<SessionStorage>().ready;
  }

  tearDown(() => Get.reset());

  for (final route in [Routes.LOGIN]) {
    testWidgets(
      'Google configuration failure on $route leaves the app usable',
      (tester) async {
        await initialize();
        final google = _FakeGoogleLogin(const Err(ValidationFailure('unused')));
        final controller = Get.put(
          AuthController(
            login: _FakeLogin(const Err(ValidationFailure('unused'))),
            register: _FakeRegister(okVoid),
            googleLogin: google,
          ),
        );
        await tester.pumpWidget(
          GetMaterialApp(
            scaffoldMessengerKey: AppSnackbar.messengerKey,
            initialRoute: route,
            getPages: AppPages.routes,
          ),
        );
        await tester.pumpAndSettle();
        // The Google button is hidden; exercise the controller's failure path.
        final signingIn = controller.loginWithGoogle();
        await tester.pumpAndSettle();
        await signingIn;
        expect(controller.errorMessage.value, 'google_sign_in_unavailable'.tr);
        expect(find.text('google_sign_in_unavailable'.tr), findsWidgets);
        expect(controller.isLoading.value, isFalse);
        expect(google.received, isEmpty);
        expect(Get.currentRoute, route);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'Signup requires a separate password sign-in before opening the app',
    (tester) async {
      await initialize();
      final session = Get.find<SessionStorage>();
      final api = Get.find<ApiClient>();
      final adapter = _SignupLoginAdapter();
      api.dio.httpClientAdapter = adapter;
      final device = _Device();
      Get.put(
        AuthController(
          login: Login(
            AuthRepositoryImpl(
              AuthRemoteDataSource(api: api, deviceService: device),
              session,
            ),
          ),
          register: _FakeRegister(okVoid),
          googleLogin: GoogleLogin(_NoopRepo()),
        ),
        permanent: true,
      );
      await tester.pumpWidget(
        GetMaterialApp(
          scaffoldMessengerKey: AppSnackbar.messengerKey,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: Routes.LOGIN,
          getPages: [
            AppPages.routes.firstWhere((page) => page.name == Routes.LOGIN),
            GetPage(
              name: Routes.REGISTER,
              page: () => const RegisterScreen(),
              binding: BindingsBuilder(
                () => Get.lazyPut(
                  () => RegistrationController(
                    RegistrationService(api, deviceService: device),
                  ),
                ),
              ),
            ),
            GetPage(
              name: Routes.FOLDER,
              page: () => const Scaffold(body: Text('App destination')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      unawaited(Get.toNamed(Routes.REGISTER));
      await tester.pumpAndSettle();
      final registration = Get.find<RegistrationController>();
      registration.accountController.text = 'newuser';
      registration.passwordController.text = 'test-password';
      registration.confirmPasswordController.text = 'test-password';
      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(RegistrationSuccess), findsOneWidget);
      expect(session.isLoggedIn, isFalse);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final auth = Get.find<AuthController>();
      expect(Get.currentRoute, Routes.LOGIN);
      expect(auth.accountController.account, 'newuser');
      expect(auth.passwordController.text, isEmpty);
      expect(session.isLoggedIn, isFalse);
      expect(adapter.requests.map((request) => request.uri.path), [
        '/api/auth/register',
      ]);
      await tester.pump(const Duration(seconds: 3));
      expect(Get.currentRoute, Routes.LOGIN);
      await tester.enterText(find.byType(EditableText).last, 'test-password');
      await tester.pumpAndSettle();
      expect(session.isLoggedIn, isFalse);
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.FOLDER);
      expect(find.text('App destination'), findsOneWidget);
      expect(session.token.value, 'signin-token');
      final signInRequest = adapter.requests.singleWhere(
        (request) => request.uri.path == '/api/auth/login',
      );
      expect(signInRequest.data['account'], 'newuser');
      expect(signInRequest.data['password'], 'test-password');
      expect(Get.key.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Register offers email signup without Google sign-in', (
    tester,
  ) async {
    await initialize();
    await tester.pumpWidget(
      GetMaterialApp(
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        initialRoute: Routes.REGISTER,
        getPages: AppPages.routes,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RegisterView), findsOneWidget);
    expect(Get.isRegistered<RegistrationController>(), isTrue);
    expect(find.text('sign_in_with_google'.tr), findsNothing);
    expect(find.text('sign_up_button'.tr), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Duplicate Google taps and results after disposal are ignored', (
    tester,
  ) async {
    await initialize();
    final pending = Completer<String?>();
    final signIn = _FakeGoogleSignIn(() => pending.future);
    final google = _FakeGoogleLogin(const Err(ValidationFailure('unused')));
    final controller = Get.put(
      AuthController(
        login: _FakeLogin(const Err(ValidationFailure('unused'))),
        register: _FakeRegister(okVoid),
        googleLogin: google,
        googleSignIn: signIn,
      ),
    );
    final first = controller.loginWithGoogle();
    await Get.find<SessionStorage>().waitForPendingWrites();
    await tester.pump();
    await controller.loginWithGoogle();
    expect(signIn.calls, 1);
    controller.onDelete();
    pending.complete('late-token');
    await first;
    expect(google.received, isEmpty);
    expect(tester.takeException(), isNull);
  });

  Future<AuthController> mountLogin(
    WidgetTester tester, {
    required Result<AuthSession> loginResult,
    _FakeLogin? login,
  }) async {
    final controller = Get.put(
      AuthController(
        googleLogin: GoogleLogin(_NoopRepo()),
        login: login ?? _FakeLogin(loginResult),
        register: _FakeRegister(okVoid),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        initialRoute: Routes.LOGIN,
        getPages: AppPages.routes,
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  for (final (account, countryCode, displayedAccount) in [
    ('name text', null, 'name text'),
    ('Nona11', null, 'Nona11'),
    ('+8550968734812', 'KH', '0968734812'),
    ('+447700900123', 'GB', '7700900123'),
  ]) {
    testWidgets('Signup prefills account $account on login', (tester) async {
      await initialize();
      final signIn = _FakeLogin(
        const Err(ValidationFailure('Test server rejection')),
      );
      final controller = await mountLogin(
        tester,
        loginResult: const Err(ValidationFailure('unused')),
        login: signIn,
      );
      controller.accountController.text = 'previous-user';
      controller.passwordController.text = 'previous-password';
      controller.isPasswordVisible.value = true;
      unawaited(Get.toNamed(Routes.REGISTER));
      await tester.pumpAndSettle();
      unawaited(
        Get.offAllNamed(
          Routes.LOGIN,
          arguments: {'account': account, 'countryCode': ?countryCode},
        ),
      );
      await tester.pumpAndSettle();
      final login = Get.find<AuthController>();
      expect(login.accountController.account, account);
      expect(login.accountController.text, displayedAccount);
      if (countryCode != null) {
        expect(login.accountController.country.code, countryCode);
      }
      expect(login.passwordController.text, isEmpty);
      expect(login.isPasswordVisible.value, isFalse);
      expect(login.isClosed, isFalse);
      await tester.enterText(find.byType(EditableText).last, 'test-password');
      unawaited(tester.binding.reassembleApplication());
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.LOGIN);
      expect(login.accountController.account, account);
      expect(login.passwordController.text, 'test-password');
      await tester.ensureVisible(find.text('sign_in_button'.tr));
      await tester.tap(find.text('sign_in_button'.tr));
      await tester.pumpAndSettle();
      expect(signIn.received?.account, account);
      expect(signIn.received?.password, 'test-password');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'edited name');
      await tester.pumpAndSettle();
      expect(login.accountController.account, 'edited name');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Phone login uses manual country selection without detecting the prefix',
    (tester) async {
      await initialize();
      final signIn = _FakeLogin(
        const Err(ValidationFailure('Test server rejection')),
      );
      await mountLogin(
        tester,
        loginResult: const Err(ValidationFailure('unused')),
        login: signIn,
      );
      for (final (number, expected) in [
        ('0968734812', '+8550968734812'),
        ('+85512345678', '+85512345678'),
        ('+447700900123', '+447700900123'),
      ]) {
        await tester.enterText(find.byType(EditableText).first, number);
        await tester.enterText(find.byType(EditableText).last, 'test-password');
        await tester.pump();
        expect(
          find.byKey(const ValueKey('account-country-picker')),
          findsOneWidget,
        );
        expect(find.text('+855'), findsOneWidget);
        await tester.ensureVisible(find.text('sign_in_button'.tr));
        await tester.tap(find.text('sign_in_button'.tr));
        await tester.pumpAndSettle();
        expect(signIn.received?.account, expected);
        expect(signIn.received?.password, 'test-password');
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('account-country-picker')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(CountryPickerDialog),
          matching: find.byType(TextField),
        ),
        'United Kingdom',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'United Kingdom'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, '7700900123');
      await tester.pump();
      expect(find.text('+44'), findsOneWidget);
      await tester.tap(find.text('sign_in_button'.tr));
      await tester.pumpAndSettle();
      expect(signIn.received?.account, '+447700900123');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Login binding remains usable after signup replaces the stack', (
    tester,
  ) async {
    final signIn = _FakeLogin(
      const Err(ValidationFailure('Test server rejection')),
    );
    Get.put<Login>(signIn, permanent: true);
    await initialize();
    await tester.pumpWidget(
      GetMaterialApp(
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        initialRoute: Routes.LOGIN,
        getPages: AppPages.routes,
      ),
    );
    await tester.pumpAndSettle();
    unawaited(Get.toNamed(Routes.REGISTER));
    await tester.pumpAndSettle();
    unawaited(Get.offAllNamed(Routes.LOGIN, arguments: {'account': 'newuser'}));
    await tester.pumpAndSettle();
    // Inspect the controller held by the visible view, rather than resolving
    // a new instance from the binding after the old route has been deleted.
    final field = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(field.controller.text, 'newuser');
    await tester.enterText(find.byType(EditableText).last, 'test-password');
    await tester.ensureVisible(find.text('sign_in_button'.tr));
    await tester.tap(find.text('sign_in_button'.tr));
    await tester.pumpAndSettle();
    expect(signIn.received?.account, 'newuser');
    expect(signIn.received?.password, 'test-password');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rejected session returns to login with a visible explanation', (
    tester,
  ) async {
    final signIn = _FakeLogin(
      const Err(ValidationFailure('Test server rejection')),
    );
    Get.put<Login>(signIn, permanent: true);
    await initialize();
    final session = Get.find<SessionStorage>();
    await session.saveSession('rejected-token', const UserData(id: 'new-user'));
    final api = Get.find<ApiClient>();
    api.dio.httpClientAdapter = _RejectedSessionAdapter();
    await tester.pumpWidget(
      GetMaterialApp(
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        initialRoute: Routes.FOLDER,
        getPages: [
          GetPage(
            name: Routes.FOLDER,
            page: () => const Scaffold(body: Text('Signed-in app')),
          ),
          AppPages.routes.firstWhere((page) => page.name == Routes.LOGIN),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final request = expectLater(
      api.dio.get('/api/folder'),
      throwsA(isA<dio.DioException>()),
    );
    await tester.pumpAndSettle();
    await request;
    await tester.pumpAndSettle();
    expect(session.isLoggedIn, isFalse);
    expect(Get.currentRoute, Routes.LOGIN);
    expect(find.text('session_rejected_message'.tr), findsOneWidget);
    await tester.enterText(find.byType(EditableText).first, 'newuser');
    await tester.enterText(find.byType(EditableText).last, 'test-password');
    await tester.ensureVisible(find.text('sign_in_button'.tr));
    await tester.tap(find.text('sign_in_button'.tr));
    await tester.pumpAndSettle();
    expect(signIn.received?.account, 'newuser');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Successful login clears the form stack and disables guest mode',
    (tester) async {
      await initialize();
      final guest = Get.find<GuestModeService>()..enable();
      expect(guest.isGuestMode.value, isTrue);

      final controller = await mountLogin(
        tester,
        loginResult: const Ok(AuthSession(token: 't', user: UserData())),
      );
      controller.accountController.text = 'someone@example.com';
      controller.passwordController.text = 'hunter2';

      // Reproduce signing in with the keyboard active while an earlier error
      // notification is still opening. Removing the login route must not leave
      // pending notifications targeting its disposed focus scope.
      final passwordField = find.byType(EditableText).last;
      await tester.showKeyboard(passwordField);
      expect(
        tester.widget<EditableText>(passwordField).focusNode.hasFocus,
        isTrue,
      );
      AppSnackbar.error('Previous login error', 'Please try again.');
      await tester.pump(const Duration(milliseconds: 60));

      await tester.tap(find.text('sign_in_button'.tr));
      await tester.pumpAndSettle();

      expect(guest.isGuestMode.value, isFalse);
      expect(Get.currentRoute, Routes.FOLDER);
      expect(controller.isLoading.value, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Failed login shows the failure and leaves the form usable', (
    tester,
  ) async {
    await initialize();
    final controller = await mountLogin(
      tester,
      loginResult: const Err(ValidationFailure('Wrong password.')),
    );
    controller.accountController.text = 'someone@example.com';
    controller.passwordController.text = 'wrong';

    await tester.tap(find.text('sign_in_button'.tr));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(controller.isLoading.value, isFalse);
    expect(controller.passwordController.text, 'wrong');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Register requires a valid email before sending credentials', (
    tester,
  ) async {
    await initialize();
    await tester.pumpWidget(
      GetMaterialApp(
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        initialRoute: Routes.REGISTER,
        getPages: AppPages.routes,
      ),
    );
    await tester.pumpAndSettle();
    final controller = Get.find<RegistrationController>();
    controller.accountController.text = 'invalid@';
    controller.passwordController.text = 'strongpass';
    controller.confirmPasswordController.text = 'strongpass';
    await tester.ensureVisible(find.text('sign_up_button'.tr));
    await tester.tap(find.text('sign_up_button'.tr));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterView), findsOneWidget);
    expect(find.text('register_email_invalid'.tr), findsOneWidget);
    expect(controller.completed.value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Register validation failure keeps the entered fields', (
    tester,
  ) async {
    await initialize();
    await tester.pumpWidget(
      GetMaterialApp(
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        initialRoute: Routes.REGISTER,
        getPages: AppPages.routes,
      ),
    );
    await tester.pumpAndSettle();
    final controller = Get.find<RegistrationController>();
    controller.accountController.text = 'new@example.com';
    controller.passwordController.text = 'strongpass';
    controller.confirmPasswordController.text = 'different';
    await tester.ensureVisible(find.text('sign_up_button'.tr));
    await tester.tap(find.text('sign_up_button'.tr));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterView), findsOneWidget);
    expect(find.text('register_password_mismatch'.tr), findsOneWidget);
    expect(controller.accountController.text, 'new@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'A login response after the screen closes does not navigate or publish feedback',
    (tester) async {
      await initialize();
      final pending = _PendingLogin();
      final guest = Get.find<GuestModeService>()..enable();
      final controller = Get.put(
        AuthController(
          login: pending,
          register: _FakeRegister(okVoid),
          googleLogin: GoogleLogin(_NoopRepo()),
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          scaffoldMessengerKey: AppSnackbar.messengerKey,
          initialRoute: Routes.LOGIN,
          getPages: AppPages.routes,
        ),
      );
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byType(EditableText).last);
      final loggingIn = controller.login();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      controller.onDelete();
      pending.result.complete(
        const Ok(AuthSession(token: 't', user: UserData())),
      );
      await loggingIn;
      await tester.pump();
      expect(guest.isGuestMode.value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
