import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/providers/auth_service.dart';
import '../../../data/providers/session_service.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';

class AuthController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _sessionService = Get.find<SessionService>();
  final _storage = GetStorage();

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
      phoneController.text = _storage.read(_keySavedPhone) ?? "";
    }
  }

  bool _validatePhone(String phone) {
    // Basic phone validation: at least 8 digits
    return phone.length >= 8 &&
        phone.length <= 15 &&
        RegExp(r'^[0-9]+$').hasMatch(phone);
  }

  void login() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showError(
        "Validation Error",
        "Please enter both phone number and password.",
      );
      return;
    }

    if (!_validatePhone(phone)) {
      _showError(
        "Invalid Phone",
        "Please enter a valid phone number (8-15 digits).",
      );
      return;
    }

    isLoading.value = true;
    try {
      if (kDebugMode) debugPrint("Attempting login for: $phone");

      final response = await _authService.login(phone, password);

      if (kDebugMode)
        debugPrint(
          "API Response: code=${response.code}, message=${response.message}",
        );

      // STRICT CHECK: The code must be 200 AND a token must be present
      if (response.code == 200 && response.token.isNotEmpty) {
        if (kDebugMode) debugPrint("Login Success. Token acquired.");

        // Handle Remember Me logic
        if (rememberMe.value) {
          _storage.write(_keyRememberMe, true);
          _storage.write(_keySavedPhone, phone);
        } else {
          _storage.write(_keyRememberMe, false);
          _storage.remove(_keySavedPhone);
        }

        await _sessionService.saveSession(response.token, response.user);

        Get.snackbar(
          "Welcome",
          "Login successful!",
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );

        Get.offAllNamed(Routes.FOLDER);
      } else {
        String msg = response.message.isNotEmpty
            ? response.message
            : "Invalid phone number or password.";
        if (response.token.isEmpty && response.code == 200) {
          msg = "Authentication failed: No token received.";
        }
        _showError("Login Failed", msg);
      }
    } catch (e) {
      _handleAuthError(e, "Login");
    } finally {
      isLoading.value = false;
    }
  }

  void register() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      _showError("Validation Error", "Please fill in all required fields.");
      return;
    }

    if (!_validatePhone(phone)) {
      _showError(
        "Invalid Phone",
        "Please enter a valid phone number (8-15 digits).",
      );
      return;
    }

    if (password.length < 6) {
      _showError(
        "Weak Password",
        "Password must be at least 6 characters long.",
      );
      return;
    }

    if (password != confirmPassword) {
      _showError("Password Mismatch", "Passwords do not match.");
      return;
    }

    isLoading.value = true;
    try {
      final response = await _authService.register(
        RegisterRequest(
          fullName: name,
          phone: phone,
          password: password,
          deviceName: "Mobile App",
          deviceType: Platform.isAndroid ? "Android" : "iOS",
        ),
      );

      if (response.code == 200 || response.code == 201) {
        Get.snackbar(
          "Success",
          "Account created successfully! Please log in.",
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 4),
        );
        Get.back();
      } else {
        _showError(
          "Registration Failed",
          response.message.isNotEmpty
              ? response.message
              : "Could not create account.",
        );
      }
    } catch (e) {
      _handleAuthError(e, "Registration");
    } finally {
      isLoading.value = false;
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
                'Reset Password',
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your phone number to receive a password reset link.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              CustomGlassTextField(
                controller: forgotPhoneController,
                placeholder: 'Phone Number',
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
                    if (phone.isEmpty || !_validatePhone(phone)) {
                      _showError('Error', 'Please enter a valid phone number');
                      return;
                    }

                    Navigator.of(sheetContext).pop();
                    isLoading.value = true;

                    final success = await _authService.forgotPassword(phone);
                    isLoading.value = false;

                    if (success) {
                      Get.snackbar(
                        'Request Sent',
                        'If an account exists for $phone, you will receive a reset link shortly.',
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                        colorText: Colors.green,
                        duration: const Duration(seconds: 5),
                      );
                    } else {
                      _showError(
                        'Error',
                        'Could not process request. Please try again later.',
                      );
                    }
                  },
                  semanticLabel: 'Send reset link',
                  borderRadius: 30,
                  foregroundColor: Colors.white,
                  glassColor: AppTheme.folderPink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    'SEND RESET LINK',
                    style: TextStyle(fontWeight: FontWeight.bold),
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

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(15),
      borderRadius: 30,
      // Warning icon
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
        size: 28,
      ),
    );
  }

  void _handleAuthError(dynamic e, String type) {
    String errorMsg = "$type failed";
    if (e is dio.DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['data'] is Map) {
          final validationErrors = data['data'] as Map;
          List<String> messages = [];
          validationErrors.forEach((key, value) {
            if (value is List) {
              messages.addAll(value.map((v) => v.toString()));
            } else if (value is String) {
              messages.add(value);
            }
          });

          if (messages.isNotEmpty) {
            errorMsg = messages.join("\n");
          } else {
            errorMsg = data['message'] ?? e.message;
          }
        } else {
          errorMsg = data['message'] ?? e.message;
        }
      } else {
        errorMsg = e.message ?? "Connection Error";
      }
    }

    if (kDebugMode) {
      debugPrint("$type Error Details: $e");
    }

    _showError("Error", errorMsg);
  }

  @override
  void onClose() {
    // Removed manual disposal of TextEditingControllers to prevent
    // "used after being disposed" errors during route transitions
    // between Login and Register screens.
    super.onClose();
  }
}
