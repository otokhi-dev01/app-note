import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/theme/colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/animations/fade_in_widget.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        "Required Fields", 
        "Please enter your email and password.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        colorText: Colors.black,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }

    isLoading.value = true;
    // Simulate a short delay for that premium iOS feel
    await Future.delayed(const Duration(milliseconds: 1200));
    final authService = Get.find<AuthService>();
    await authService.login(emailController.text.trim(), passwordController.text.trim());
    isLoading.value = false;
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: const CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeInWidget(
            duration: const Duration(milliseconds: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
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
                const SizedBox(height: 48),
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Securely sync your notes with iCloud and access them anywhere.',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black.withValues(alpha: 0.45),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Form Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CupertinoTextField(
                        controller: controller.emailController,
                        placeholder: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE5E5EA),
                              width: 0.5,
                            ),
                          ),
                        ),
                        placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
                        style: const TextStyle(fontSize: 17),
                      ),
                      CupertinoTextField(
                        controller: controller.passwordController,
                        placeholder: 'Password',
                        obscureText: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: const BoxDecoration(),
                        placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
                        style: const TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(16),
                    onPressed: controller.isLoading.value ? null : controller.login,
                    child: controller.isLoading.value
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                  ),
                )),
                
                const SizedBox(height: 16),
                
                Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Get.snackbar(
                        "Forgot Password", 
                        "Password reset is not available in the demo.",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        margin: const EdgeInsets.all(16),
                        borderRadius: 16,
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
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
                            color: Colors.black.withValues(alpha: 0.4),
                            fontSize: 15,
                          ),
                        ),
                        const Text(
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
