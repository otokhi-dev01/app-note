import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../domain/repositories/auth_repository.dart';


class RegisterController extends GetxController {
  final AuthRepository authRepository;

  RegisterController({
    required this.authRepository,
  });


  final TextEditingController fullNameController =
  TextEditingController();

  final TextEditingController phoneController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController confirmPasswordController =
  TextEditingController();

  final RxBool isLoading = false.obs;

  final RxBool obscurePassword = true.obs;

  final RxBool obscureConfirmPassword = true.obs;

  final RxString errorMessage = ''.obs;

  Future<void> register() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final String fullName =
    fullNameController.text.trim();

    final String phone =
    phoneController.text.trim();

    final String password =
        passwordController.text;

    final String confirmPassword =
        confirmPasswordController.text;

    final String? validationError = _validate(
      fullName: fullName,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (validationError != null) {
      errorMessage.value = validationError;
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      await authRepository.register(
        fullName: fullName,
        phone: phone,
        password: password,
        deviceName: _deviceName,
        deviceType: _deviceType,
      );

      final bool isAuthenticated =
      await authRepository.isLoggedIn();

      if (isAuthenticated) {
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      Get.offNamed(
        AppRoutes.login,
        arguments: <String, dynamic>{
          'phone': phone,
          'registered': true,
        },
      );
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.toggle();
  }

  void openLogin() {
    Get.offNamed(AppRoutes.login);
  }

  String? _validate({
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
  }) {
    if (fullName.isEmpty) {
      return 'Please enter your full name.';
    }

    if (fullName.length < 2) {
      return 'Full name must contain at least 2 characters.';
    }

    if (phone.isEmpty) {
      return 'Please enter your phone number.';
    }

    final String normalizedPhone =
    phone.replaceAll(
      RegExp(r'[\s\-()]'),
      '',
    );

    final RegExp phonePattern =
    RegExp(r'^\+?[0-9]{8,15}$');

    if (!phonePattern.hasMatch(normalizedPhone)) {
      return 'Please enter a valid phone number.';
    }

    if (password.isEmpty) {
      return 'Please enter a password.';
    }

    if (password.length < 6) {
      return 'Password must contain at least 6 characters.';
    }

    if (confirmPassword.isEmpty) {
      return 'Please confirm your password.';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    return null;
  }

  String get _deviceType {
    if (kIsWeb) {
      return 'web';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  String get _deviceName {
    return 'Piisiit Note ${_deviceType.toUpperCase()}';
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('ApiException: ', '')
        .trim();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.onClose();
  }
}
