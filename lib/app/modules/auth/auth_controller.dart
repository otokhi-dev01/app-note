import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/models/auth_model.dart';
import '../../data/services/auth_service.dart';
import '../../routes/app_pages.dart';

class AuthController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _storage = GetStorage();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  final isLoading = false.obs;

  void login() async {
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all fields", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      final response = await _authService.login(phoneController.text, passwordController.text);
      if (response.code == 200) {
        _storage.write('token', response.token);
        Get.offAllNamed(Routes.FOLDER);
      } else {
        Get.snackbar("Error", response.message, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      String errorMsg = "Login failed";
      if (e is dio.DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? "Connection Error";
      }
      Get.snackbar("Error", errorMsg, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void register() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all fields", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      await _authService.register(RegisterRequest(
        fullName: nameController.text,
        phone: phoneController.text,
        password: passwordController.text,
        deviceName: "Mobile App",
        deviceType: Platform.isAndroid ? "Android" : "iOS",
      ));
      Get.snackbar("Success", "Account created! Please login.", snackPosition: SnackPosition.BOTTOM);
      Get.back();
    } catch (e) {
      Get.snackbar("Error", "Registration failed.", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
