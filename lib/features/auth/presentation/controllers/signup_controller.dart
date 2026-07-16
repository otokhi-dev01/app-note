import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/core/network/api_endpoints.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';

class SignupController extends GetxController {
  SignupController({AuthRepository? authRepository})
    : _authRepository = authRepository;

  final AuthRepository? _authRepository;
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  Future<void> signup() async {
    if (isLoading.value) return;

    final context = Get.context;
    final colors = context == null
        ? const ColorScheme.light()
        : Theme.of(context).colorScheme;
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Missing Information',
        'Please enter your phone number and password.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: colors.surface,
        colorText: colors.onSurface,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }

    if (phone.length < ApiEndpoints.minimumPhoneLength ||
        phone.length > ApiEndpoints.maximumPhoneLength) {
      Get.snackbar(
        'Invalid Phone Number',
        'Phone number must be between ${ApiEndpoints.minimumPhoneLength} and '
            '${ApiEndpoints.maximumPhoneLength} characters.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: colors.surface,
        colorText: colors.onSurface,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }

    if (password.length < ApiEndpoints.minimumPasswordLength ||
        password.length > ApiEndpoints.maximumPasswordLength) {
      Get.snackbar(
        'Invalid Password',
        'Password must be between ${ApiEndpoints.minimumPasswordLength} and '
            '${ApiEndpoints.maximumPasswordLength} characters.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: colors.surface,
        colorText: colors.onSurface,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }

    isLoading.value = true;
    final authRepository = _authRepository ?? Get.find<AuthRepository>();
    late final bool success;
    try {
      success = await authRepository.signup(phone, password);
    } finally {
      isLoading.value = false;
    }

    if (success) {
      Get.offAllNamed(AppRoutes.login, arguments: {'phone': phone});
      Get.snackbar(
        'Account Created',
        'Your account is ready. Sign in with your phone number.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: colors.surface,
        colorText: colors.onSurface,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }

    Get.snackbar(
      'Registration Failed',
      authRepository.lastError ??
          'Please check your information and try again.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: colors.error,
      colorText: colors.onError,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
    );
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
