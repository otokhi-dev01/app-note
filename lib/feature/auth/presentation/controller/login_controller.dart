import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/validation/auth_input_validator.dart';
import '../utils/auth_error_message.dart';

class LoginController extends GetxController {
  final AuthRepository authRepository;

  LoginController({required this.authRepository});

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();

    final dynamic arguments = Get.arguments;

    if (arguments is! Map) {
      return;
    }

    final String phone = arguments['phone']?.toString() ?? '';

    final bool registered = arguments['registered'] == true;

    if (phone.trim().isNotEmpty) {
      phoneController.text = phone;
    }

    if (registered) {
      successMessage.value =
          'Your account was created successfully. Sign in to continue.';
    }
  }

  Future<void> login() async {
    if (isLoading.value) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final String phone = AuthInputValidator.normalizePhone(
      phoneController.text,
    );

    final String password = passwordController.text;

    final String? phoneError = AuthInputValidator.validatePhone(phone);
    if (phoneError != null) {
      errorMessage.value = phoneError;
      return;
    }

    final String? passwordError = AuthInputValidator.validatePassword(password);
    if (passwordError != null) {
      errorMessage.value = passwordError;
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      await authRepository.login(phone: phone, password: password);

      Get.offAllNamed(AppRoutes.home);
    } catch (error) {
      errorMessage.value = authErrorMessage(error);
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  void openRegister() {
    Get.toNamed(AppRoutes.register);
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
