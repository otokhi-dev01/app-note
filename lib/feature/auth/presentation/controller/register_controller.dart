import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/validation/auth_input_validator.dart';
import '../utils/auth_error_message.dart';

class RegisterController extends GetxController {
  final AuthRepository authRepository;

  RegisterController({required this.authRepository});

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  final RxBool isLoading = false.obs;

  final RxBool obscurePassword = true.obs;

  final RxBool obscureConfirmPassword = true.obs;

  final RxString errorMessage = ''.obs;

  Future<void> register() async {
    if (isLoading.value) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final String phone = AuthInputValidator.normalizePhone(
      phoneController.text,
    );

    final String password = passwordController.text;

    final String confirmPassword = confirmPasswordController.text;

    final String? validationError = _validate(
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

      final bool isAuthenticated = await authRepository.register(
        phone: phone,
        password: password,
      );

      if (isAuthenticated) {
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      Get.offAllNamed(
        AppRoutes.login,
        arguments: <String, dynamic>{'phone': phone, 'registered': true},
      );
    } catch (error) {
      errorMessage.value = authErrorMessage(error);
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
    Get.offAllNamed(AppRoutes.login);
  }

  String? _validate({
    required String phone,
    required String password,
    required String confirmPassword,
  }) {
    final String? phoneError = AuthInputValidator.validatePhone(phone);
    if (phoneError != null) {
      return phoneError;
    }

    final String? passwordError = AuthInputValidator.validatePassword(password);
    if (passwordError != null) {
      return passwordError;
    }

    if (confirmPassword.isEmpty) {
      return 'Please confirm your password.';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    return null;
  }

  @override
  void onClose() {
    /* 
     * Disposal of TextEditingControllers is omitted to prevent 
     * 'used after being disposed' errors during route transitions. 
     * GC will handle cleanup once views are unmounted.
     */
    super.onClose();
  }
}
