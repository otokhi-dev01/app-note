import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/features/auth/data/services/google_sign_in_service.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/features/auth/presentation/controllers/account_input_controller.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/core/controllers/encryption_controller.dart';

/// Backs both the login and register screens.
///
/// Validation and the "is this response actually a success?" decision now live
/// in the `Login` / `Register` use cases, so this class only owns form state
/// and navigation.
class AuthController extends GetxController {
  final Login _login;
  final Register _register;
  final GoogleLogin _googleLogin;
  final GoogleSignInService _googleSignIn;

  AuthController({
    required Login login,
    required Register register,
    required GoogleLogin googleLogin,
    GoogleSignInService? googleSignIn,
  }) : _login = login,
       _register = register,
       _googleLogin = googleLogin,
       _googleSignIn = googleSignIn ?? GoogleSignInService();

  final _guestMode = Get.find<GuestModeService>();
  final accountController = AccountInputController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Clear legacy saved credentials if present
    final storage = GetStorage();
    storage.remove('remember_me');
    storage.remove('saved_phone');
    storage.remove('saved_account');
  }

  void togglePasswordVisibility() => isPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();

  Future<void> continueWithoutAccount() async {
    if (isLoading.value || isClosed) return;
    Get.find<SessionStorage>().sessionRejected.value = false;
    errorMessage.value = '';
    isLoading.value = true;
    try {
      _guestMode.enable();
      _replaceAuthStack(Routes.FOLDER);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  void _replaceAuthStack(String route) {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    try {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } catch (_) {}
    unawaited(Get.offAllNamed(route));
  }

  Future<void> login() async {
    if (isLoading.value || isClosed) return;
    FocusManager.instance.primaryFocus?.unfocus();
    errorMessage.value = '';
    final account = accountController.account;

    final session = Get.find<SessionStorage>();
    await session.clearSession();
    session.sessionRejected.value = false;

    isLoading.value = true;
    try {
      final result = await _login(
        LoginParams(account: account, password: passwordController.text),
      );

      switch (result) {
        case Ok():
          errorMessage.value = '';
          if (kDebugMode) {
            debugPrint('[AUTH] Login logic successful. Disable guest mode.');
          }
          _guestMode.disable();
          AppSnackbar.success('welcome_title'.tr, 'login_success_message'.tr);

          // Setup E2EE safely without blocking navigation
          try {
            unawaited(Get.find<EncryptionController>().setupForCurrentUser());
          } catch (_) {}

          if (kDebugMode) debugPrint('[AUTH] Navigating to Folder view...');
          _replaceAuthStack(Routes.FOLDER);
        case Err(:final failure):
          errorMessage.value = failure.message;
          AppSnackbar.failure('login_failed_title'.tr, failure);
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> loginWithGoogle() async {
    if (isLoading.value || isClosed) return;
    FocusManager.instance.primaryFocus?.unfocus();
    errorMessage.value = '';
    final session = Get.find<SessionStorage>();
    await session.clearSession();
    session.sessionRejected.value = false;

    isLoading.value = true;
    try {
      final idToken = await _googleSignIn.signInIdToken();
      if (idToken == null) return;

      final result = await _googleLogin(idToken);

      switch (result) {
        case Ok():
          errorMessage.value = '';
          if (kDebugMode) {
            debugPrint('[AUTH] Google login successful. Setting up E2EE...');
          }
          _guestMode.disable();
          AppSnackbar.success('welcome_title'.tr, 'login_success_message'.tr);
          try {
            unawaited(Get.find<EncryptionController>().setupForCurrentUser());
          } catch (_) {}
          _replaceAuthStack(Routes.FOLDER);
        case Err(:final failure):
          errorMessage.value = failure.message;
          AppSnackbar.failure('login_failed_title'.tr, failure);
      }
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') return;
      final msg = (e.code == 'google_not_configured'
              ? 'google_sign_in_unavailable'
              : 'google_sign_in_failed')
          .tr;
      errorMessage.value = msg;
      AppSnackbar.error('login_failed_title'.tr, msg);
    } catch (_) {
      if (!isClosed) {
        final msg = 'google_sign_in_failed'.tr;
        errorMessage.value = msg;
        AppSnackbar.error('login_failed_title'.tr, msg);
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> register() async {
    if (isLoading.value || isClosed) return;
    FocusManager.instance.primaryFocus?.unfocus();
    errorMessage.value = '';

    isLoading.value = true;
    try {
      final result = await _register(
        RegisterParams(
          account: accountController.account,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
        ),
      );

      switch (result) {
        case Ok():
          errorMessage.value = '';
          AppSnackbar.success(
            'success_title'.tr,
            'register_success_message'.tr,
          );
          _replaceAuthStack(Routes.LOGIN);
        case Err(:final failure):
          errorMessage.value = failure.message;
          AppSnackbar.failure('register_failed_title'.tr, failure);
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> forgotPassword() async {
    if (isLoading.value) return;
    await Get.toNamed(Routes.FORGOT_PASSWORD);
  }

  @override
  void onClose() {
    // Controllers are intentionally not disposed here: Login and Register share
    // this instance, and disposing during their route transition triggers
    // "used after being disposed".
    super.onClose();
  }
}
