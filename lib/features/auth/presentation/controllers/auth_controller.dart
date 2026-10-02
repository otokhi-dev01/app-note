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
    isLoading.value = true;
    try {
      _guestMode.enable();
      await _replaceAuthStack(Routes.FOLDER);
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> _replaceAuthStack(String route) async {
    FocusManager.instance.primaryFocus?.unfocus();
    // Let the current frame and its queued focus notifications finish while
    // the old route's focus scope is still alive. Keep submission locked until
    // navigation has been issued, and ignore responses to closed controllers.
    await WidgetsBinding.instance.endOfFrame;
    FocusManager.instance.applyFocusChangesIfNeeded();
    if (isClosed) return;
    unawaited(Get.offAllNamed(route));
  }

  Future<void> login() async {
    if (isLoading.value || isClosed) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final account = accountController.account;

    isLoading.value = true;
    try {
      final result = await _login(
        LoginParams(account: account, password: passwordController.text),
      );
      if (isClosed) return;

      switch (result) {
        case Ok():
          if (kDebugMode) {
            debugPrint(
              '[AUTH] Login logic successful. Disable guest mode.',
            );
          }
          _guestMode.disable();
          AppSnackbar.success('welcome_title'.tr, 'login_success_message'.tr);

          // Setup E2EE. Shared unawaited handles the background task.
          unawaited(Get.find<EncryptionController>().setupForCurrentUser());

          if (kDebugMode) debugPrint('[AUTH] Navigating to Folder view...');
          await _replaceAuthStack(Routes.FOLDER);
        case Err(:final failure):
          AppSnackbar.failure('login_failed_title'.tr, failure);
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    if (isLoading.value || isClosed) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    try {
      final idToken = await _googleSignIn.signInIdToken();
      if (isClosed || idToken == null) return;

      final result = await _googleLogin(idToken);
      if (isClosed) return;

      switch (result) {
        case Ok():
          if (kDebugMode) {
            debugPrint('[AUTH] Google login successful. Setting up E2EE...');
          }
          _guestMode.disable();
          AppSnackbar.success('welcome_title'.tr, 'login_success_message'.tr);
          unawaited(Get.find<EncryptionController>().setupForCurrentUser());
          await _replaceAuthStack(Routes.FOLDER);
        case Err(:final failure):
          AppSnackbar.failure('login_failed_title'.tr, failure);
      }
    } on PlatformException catch (e) {
      if (isClosed || e.code == 'sign_in_canceled') return;
      AppSnackbar.error(
        'login_failed_title'.tr,
        (e.code == 'google_not_configured'
                ? 'google_sign_in_unavailable'
                : 'google_sign_in_failed')
            .tr,
      );
    } catch (_) {
      if (!isClosed) {
        AppSnackbar.error('login_failed_title'.tr, 'google_sign_in_failed'.tr);
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (isLoading.value || isClosed) return;
    FocusManager.instance.primaryFocus?.unfocus();

    isLoading.value = true;
    try {
      final result = await _register(
        RegisterParams(
          account: accountController.account,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
        ),
      );
      if (isClosed) return;

      switch (result) {
        case Ok():
          AppSnackbar.success(
            'success_title'.tr,
            'register_success_message'.tr,
          );
          await _replaceAuthStack(Routes.LOGIN);
        case Err(:final failure):
          AppSnackbar.failure('register_failed_title'.tr, failure);
      }
    } finally {
      if (!isClosed) isLoading.value = false;
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
