import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../app/services/auth_service.dart';
import '../../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  final AuthService _authService = Get.find<AuthService>();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final deviceNameController = TextEditingController();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Clear error when user starts typing
    phoneController.addListener(() => hasError.value = false);
    passwordController.addListener(() => hasError.value = false);
  }

  void togglePasswordVisibility() => obscurePassword.value = !obscurePassword.value;

  Future<void> login() async {
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      hasError.value = true;
      Get.snackbar('Error', 'Please fill in all fields');
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    try {
      final response = await _repository.login(
        phoneController.text,
        passwordController.text,
      );

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        _authService.login(token);
        Get.offAllNamed(AppRoutes.home);
      } else {
        hasError.value = true;
        Get.snackbar('Error', response.data['message'] ?? 'Login failed');
      }
    } catch (e) {
      hasError.value = true;
      Get.snackbar('Error', 'An error occurred during login');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (fullNameController.text.isEmpty || 
        phoneController.text.isEmpty || 
        passwordController.text.isEmpty || 
        deviceNameController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields');
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    try {
      final response = await _repository.register(
        fullName: fullNameController.text,
        phone: phoneController.text,
        password: passwordController.text,
        deviceName: deviceNameController.text,
      );

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Account created successfully. Please login.');
        Get.back();
      } else {
        hasError.value = true;
        Get.snackbar('Error', response.data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      hasError.value = true;
      Get.snackbar('Error', 'An error occurred during registration');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    deviceNameController.dispose();
    super.onClose();
  }
}
