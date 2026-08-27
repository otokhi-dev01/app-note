import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/routes/app_pages.dart';

/// Backs both the login and register screens.
///
/// Validation and the "is this response actually a success?" decision now live
/// in the `Login` / `Register` use cases, so this class only owns form state
/// and navigation.
class AuthController extends GetxController {
  final Login _login;
  final Register _register;
  final ForgotPassword _forgotPassword;

  AuthController({
    required Login login,
    required Register register,
    required ForgotPassword forgotPassword,
  }) : _login = login,
       _register = register,
       _forgotPassword = forgotPassword;

  final _storage = GetStorage();
  final _guestMode = Get.find<GuestModeService>();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final rememberMe = true.obs;

  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedPhone = 'saved_phone';

  @override
  void onInit() {
    super.onInit();
    _loadRememberMe();
  }

  void togglePasswordVisibility() => isPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();
  void toggleRememberMe() => rememberMe.toggle();

  void _loadRememberMe() {
    rememberMe.value = _storage.read(_keyRememberMe) ?? false;
    if (rememberMe.value) {
      phoneController.text = _storage.read(_keySavedPhone) ?? '';
    }
  }

  Future<void> login() async {
    if (isLoading.value) return;
    final phone = phoneController.text.trim();

    isLoading.value = true;
    try {
      final result = await _login(
        LoginParams(phone: phone, password: passwordController.text.trim()),
      );

      switch (result) {
        case Ok():
          _guestMode.disable();
          _persistRememberMe(phone);
          AppSnackbar.success('welcome_title'.tr, 'login_success_message'.tr);
          unawaited(Get.offAllNamed(Routes.FOLDER));
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
          fullName: nameController.text.trim(),
          phone: phoneController.text.trim(),
          password: passwordController.text.trim(),
          confirmPassword: confirmPasswordController.text.trim(),
          deviceName: 'Mobile App',
          deviceType: Platform.isAndroid ? 'Android' : 'iOS',
        ),
      );

      switch (result) {
        case Ok():
          _guestMode.disable();
          AppSnackbar.success(
            'success_title'.tr,
            'register_success_message'.tr,
          );
          unawaited(Get.offAllNamed(Routes.LOGIN));
        case Err(:final failure):
          AppSnackbar.failure('register_failed_title'.tr, failure);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _persistRememberMe(String phone) {
    if (rememberMe.value) {
      _storage.write(_keyRememberMe, true);
      _storage.write(_keySavedPhone, phone);
    } else {
      _storage.write(_keyRememberMe, false);
      _storage.remove(_keySavedPhone);
    }
  }

  Future<void> forgotPassword() async {
    await Get.toNamed(
      Routes.FORGOT_PASSWORD,
      arguments: {
        'initialPhone': phoneController.text.trim(),
        'onSubmit': _submitForgotPassword,
      },
    );
  }

  Future<bool> _submitForgotPassword(String phone) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    try {
      final result = await _forgotPassword(phone);
      switch (result) {
        case Ok():
          AppSnackbar.success(
            'reset_request_sent_title'.tr,
            'reset_request_sent_message'.trParams({'phone': phone}),
          );
          return true;
        case Err(:final failure):
          AppSnackbar.failure('forgot_password_title'.tr, failure);
          return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // Controllers are intentionally not disposed here: Login and Register share
    // this instance, and disposing during their route transition triggers
    // "used after being disposed".
    super.onClose();
  }
}
