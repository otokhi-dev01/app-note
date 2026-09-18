import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';
import 'package:Note/features/auth/domain/repositories/auth_repository.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/auth/presentation/controllers/auth_controller.dart';
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

class _NoopRepo implements AuthRepository {
  const _NoopRepo();
  @override
  noSuchMethod(Invocation invocation) =>
      Future.value(const Err(ValidationFailure('unused')));
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
  setUp(() {
    Get.testMode = true;
    InitialBinding().dependencies();
  });
  tearDown(() => Get.reset());

  Future<AuthController> mountLogin(
    WidgetTester tester, {
    required Result<AuthSession> loginResult,
  }) async {
    final controller = Get.put(
      AuthController(
        login: _FakeLogin(loginResult),
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

  testWidgets('Successful login clears the form stack and disables guest mode', (
    tester,
  ) async {
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
    expect(tester.widget<EditableText>(passwordField).focusNode.hasFocus, isTrue);
    AppSnackbar.error('Previous login error', 'Please try again.');
    await tester.pump(const Duration(milliseconds: 60));

    await tester.tap(find.text('sign_in_button'.tr));
    await tester.pumpAndSettle();
    // Let the success snackbar's auto-dismiss timer finish before the test
    // ends, or it leaks a pending timer into the next test.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(guest.isGuestMode.value, isFalse);
    expect(Get.currentRoute, Routes.FOLDER);
    expect(controller.isLoading.value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed login shows the failure and leaves the form usable', (
    tester,
  ) async {
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

  testWidgets('Register navigates to Login on success', (tester) async {
    final controller = Get.put(
      AuthController(
        login: _FakeLogin(const Err(ValidationFailure('unused'))),
        register: _FakeRegister(okVoid),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        initialRoute: Routes.REGISTER,
        getPages: AppPages.routes,
      ),
    );
    await tester.pumpAndSettle();

    controller.accountController.text = 'new@example.com';
    controller.passwordController.text = 'strongpass';
    controller.confirmPasswordController.text = 'strongpass';

    await tester.tap(find.text('sign_up_button'.tr));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Register failure keeps the entered fields and shows on Register', (
    tester,
  ) async {
    final controller = Get.put(
      AuthController(
        login: _FakeLogin(const Err(ValidationFailure('unused'))),
        register: _FakeRegister(
          const Err(ValidationFailure('Passwords do not match.')),
        ),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        initialRoute: Routes.REGISTER,
        getPages: AppPages.routes,
      ),
    );
    await tester.pumpAndSettle();

    controller.accountController.text = 'new@example.com';
    controller.passwordController.text = 'strongpass';
    controller.confirmPasswordController.text = 'different';

    await tester.tap(find.text('sign_up_button'.tr));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterView), findsOneWidget);
    expect(controller.accountController.text, 'new@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('A login response after the screen closes does not navigate or publish feedback', (tester) async {
    final pending = _PendingLogin();
    final guest = Get.find<GuestModeService>()..enable();
    final controller = Get.put(AuthController(login: pending, register: _FakeRegister(okVoid)));
    await tester.pumpWidget(GetMaterialApp(
      scaffoldMessengerKey: AppSnackbar.messengerKey,
      initialRoute: Routes.LOGIN,
      getPages: AppPages.routes,
    ));
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(EditableText).last);
    final loggingIn = controller.login();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    controller.onDelete();
    pending.result.complete(const Ok(AuthSession(token: 't', user: UserData())));
    await loggingIn;
    await tester.pump();
    expect(guest.isGuestMode.value, isTrue);
    expect(tester.takeException(), isNull);
  });
}
