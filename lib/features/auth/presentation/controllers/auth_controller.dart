import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/core/utils/validators.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

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
    final context = Get.context;
    if (context == null) return;

    final forgotPhoneController = TextEditingController(
      text: phoneController.text,
    );
    try {
      await CustomGlassSheet.show<void>(
        context: context,
        isScrollable: true,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'reset_password_title'.tr,
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'reset_password_desc'.tr,
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              CustomGlassTextField(
                controller: forgotPhoneController,
                placeholder: 'phone_number_hint'.tr,
                prefixIcon: const Icon(Icons.phone, color: AppTheme.folderPink),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                textStyle: Theme.of(sheetContext).textTheme.bodyLarge,
                useOwnLayer: false,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CustomGlassButton(
                  onPressed: () async {
                    final phone = forgotPhoneController.text.trim();
                    final invalid = Validators.phone(phone);
                    if (invalid != null) {
                      AppSnackbar.warning('invalid_phone_title'.tr, invalid);
                      return;
                    }

                    Navigator.of(sheetContext).pop();
                    isLoading.value = true;
                    try {
                      // Always fails today: the server has no reset route. The
                      // use case surfaces that reason rather than pretending a
                      // link was sent.
                      final result = await _forgotPassword(phone);
                      if (result case Err(:final failure)) {
                        AppSnackbar.failure('reset_password_title'.tr, failure);
                      } else {
                        AppSnackbar.success(
                          'reset_request_sent_title'.tr,
                          'reset_request_sent_message'.trParams({
                            'phone': phone,
                          }),
                        );
                      }
                    } finally {
                      isLoading.value = false;
                    }
                  },
                  semanticLabel: 'Send reset link',
                  borderRadius: 30,
                  foregroundColor: Colors.white,
                  glassColor: AppTheme.folderPink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'send_reset_link'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      forgotPhoneController.dispose();
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
