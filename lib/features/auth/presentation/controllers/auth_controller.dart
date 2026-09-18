import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/error/result.dart';
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

  AuthController({required Login login, required Register register})
    : _login = login,
      _register = register;

  final _storage = GetStorage();
  final _guestMode = Get.find<GuestModeService>();

  final accountController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final rememberMe = true.obs;

  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedPhone = 'saved_phone';
  static const String _keySavedAccount = 'saved_account';

  @override
  void onInit() {
    super.onInit();
    _loadRememberMe();
  }

  void togglePasswordVisibility() => isPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();
  void toggleRememberMe() => rememberMe.toggle();

  void continueWithoutAccount() {
    if (isLoading.value) return;
    _guestMode.enable();
    unawaited(Get.offAllNamed(Routes.FOLDER));
  }

  void _loadRememberMe() {
    rememberMe.value = _storage.read(_keyRememberMe) ?? false;
    if (rememberMe.value) {
      accountController.text =
          _storage.read(_keySavedAccount) ??
          _storage.read(_keySavedPhone) ??
          '';
    }
  }

  Future<void> login() async {
    if (isLoading.value) return;
    final account = accountController.text.trim();

    isLoading.value = true;
    try {
      final result = await _login(
        LoginParams(account: account, password: passwordController.text),
      );

      switch (result) {
        case Ok():
          if (kDebugMode) {
            debugPrint(
              '[AUTH] Login logic successful. Disable guest mode and persisting.',
            );
          }
          _guestMode.disable();
          _persistRememberMe(account);
          AppSnackbar.success('welcome_title'.tr, 'login_success_message'.tr);

          // Setup E2EE. Shared unawaited handles the background task.
          unawaited(Get.find<EncryptionController>().setupForCurrentUser());

          if (kDebugMode) debugPrint('[AUTH] Navigating to Folder view...');
          // Use a slight delay or next-tick to ensure the snackbar and state
          // updates settle before clearing the entire navigation stack.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(Routes.FOLDER);
          });
        case Err(:final failure):
          AppSnackbar.failure('login_failed_title'.tr, failure);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final result = await _register(
        RegisterParams(
          account: accountController.text.trim(),
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
        ),
      );

      switch (result) {
        case Ok():
          AppSnackbar.success(
            'success_title'.tr,
            'register_success_message'.tr,
          );
          // Deferred to the next frame for the same reason as login(): clearing
          // the navigation stack immediately can tear down the snackbar's
          // overlay while it's still transitioning in.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(Routes.LOGIN);
          });
        case Err(:final failure):
          AppSnackbar.failure('register_failed_title'.tr, failure);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _persistRememberMe(String account) {
    if (rememberMe.value) {
      _storage.write(_keyRememberMe, true);
      _storage.write(_keySavedAccount, account);
      _storage.remove(_keySavedPhone);
    } else {
      _storage.write(_keyRememberMe, false);
      _storage.remove(_keySavedPhone);
      _storage.remove(_keySavedAccount);
    }
  }

  Future<void> forgotPassword() async {
    if (isLoading.value) return;
    await Get.toNamed(
      Routes.FORGOT_PASSWORD,
      arguments: {'initialAccount': accountController.text.trim()},
    );
  }

  @override
  void onClose() {
    // Controllers are intentionally not disposed here: Login and Register share
    // this instance, and disposing during their route transition triggers
    // "used after being disposed".
    super.onClose();
  }
}
