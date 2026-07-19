import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../domain/repositories/auth_repository.dart';

class LoginController extends GetxController {
  final AuthRepository authRepository;

  LoginController({
    required this.authRepository,
  });

  final TextEditingController phoneController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

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

    final String phone =
        arguments['phone']?.toString() ?? '';

    final bool registered =
        arguments['registered'] == true;

    if (phone.trim().isNotEmpty) {
      phoneController.text = phone;
    }

    if (registered) {
      successMessage.value =
      'Your account was created successfully. Sign in to continue.';
    }
  }

  Future<void> login() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final String phone =
    phoneController.text.trim();

    final String password =
        passwordController.text;

    if (phone.isEmpty) {
      errorMessage.value =
      'Please enter your phone number.';
      return;
    }

    if (password.isEmpty) {
      errorMessage.value =
      'Please enter your password.';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      await authRepository.login(
        phone: phone,
        password: password,
      );

      Get.offAllNamed(AppRoutes.home);
    } catch (error) {
      errorMessage.value = _cleanError(error);
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

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('ApiException: ', '')
        .trim();
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();

    super.onClose();
  }
}