import 'package:notes/data/services/auth_service.dart';
import 'package:notes/core/constants/api_config.dart';
import 'package:notes/app/routes/app_routes.dart';
import 'package:notes/app/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/shared/animations/fade_in_widget.dart';

class LoginController extends GetxController {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  Future<void> login() async {
    if (isLoading.value) return;

    final colors = Theme.of(Get.context!).colorScheme;
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      Get.snackbar(
        "Required Fields",
        "Please enter your phone number and password.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: colors.surface,
        colorText: colors.onSurface,
        margin: EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }

    if (phone.length < ApiConfig.minimumPhoneLength ||
        phone.length > ApiConfig.maximumPhoneLength) {
      Get.snackbar(
        'Invalid Phone Number',
        'Phone number must be between ${ApiConfig.minimumPhoneLength} and '
            '${ApiConfig.maximumPhoneLength} characters.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: colors.surface,
        colorText: colors.onSurface,
        margin: EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }

    if (password.length < ApiConfig.minimumPasswordLength ||
        password.length > ApiConfig.maximumPasswordLength) {
      Get.snackbar(
        'Invalid Password',
        'Password must be between ${ApiConfig.minimumPasswordLength} and '
            '${ApiConfig.maximumPasswordLength} characters.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: colors.surface,
        colorText: colors.onSurface,
        margin: EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }

    isLoading.value = true;
    final authService = Get.find<AuthService>();
    final success = await authService.login(phone, password);
    isLoading.value = false;

    if (success) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    Get.snackbar(
      'Sign In Failed',
      authService.lastError ?? 'Please check your credentials and try again.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: colors.error,
      colorText: colors.onError,
      margin: EdgeInsets.all(16),
      borderRadius: 16,
    );
  }

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments is Map && arguments['phone'] is String) {
      phoneController.text = arguments['phone'] as String;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: FadeInWidget(
            duration: Duration(milliseconds: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.3
                                : 0.06,
                          ),
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/icons/notes.jpg',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 48),
                Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: colors.onSurface,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Enter your phone number and password to access your notes.',
                  style: TextStyle(
                    fontSize: 17,
                    color: colors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 40),
                // Form Section
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.25
                              : 0.03,
                        ),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CupertinoTextField(
                        controller: controller.phoneController,
                        placeholder: 'Phone number',
                        keyboardType: TextInputType.phone,
                        autofillHints: [AutofillHints.telephoneNumber],
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                          LengthLimitingTextInputFormatter(
                            ApiConfig.maximumPhoneLength,
                          ),
                        ],
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colors.outlineVariant,
                              width: 0.5,
                            ),
                          ),
                        ),
                        placeholderStyle: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                        style: TextStyle(fontSize: 17, color: colors.onSurface),
                      ),
                      CupertinoTextField(
                        controller: controller.passwordController,
                        placeholder: 'Password',
                        obscureText: true,
                        autofillHints: [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        enableSuggestions: false,
                        autocorrect: false,
                        onSubmitted: (_) => controller.login(),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            ApiConfig.maximumPasswordLength,
                          ),
                        ],
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(),
                        placeholderStyle: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                        style: TextStyle(fontSize: 17, color: colors.onSurface),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.login,
                      child: controller.isLoading.value
                          ? CupertinoActivityIndicator(color: Colors.white)
                          : Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Get.toNamed(AppRoutes.signup),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
