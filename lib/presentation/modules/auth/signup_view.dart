import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/theme/colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/animations/fade_in_widget.dart';

class SignupController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  Future<void> signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar(
        "Missing Information", 
        "Please fill in all fields to create your account.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        colorText: Colors.black,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }

    isLoading.value = true;
    
    // Aesthetic delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final success = await Get.find<AuthService>().signup(name, email, password);
    isLoading.value = false;

    if (success) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.snackbar(
        "Signup Failed", 
        "There was an error creating your account. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.left_chevron, color: AppColors.orange, size: 22),
              Text('Sign In', style: TextStyle(color: AppColors.orange, fontSize: 17)),
            ],
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeInWidget(
            duration: const Duration(milliseconds: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icons/notes.jpg',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Join us and start organizing your thoughts across all your devices.',
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
                        controller: controller.nameController,
                        placeholder: 'Full Name',
                        textCapitalization: TextCapitalization.words,
                        padding: const EdgeInsets.all(16),
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
                        controller: controller.emailController,
                        placeholder: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.all(16),
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
                    onPressed: controller.isLoading.value ? null : controller.signup,
                    child: controller.isLoading.value
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                  ),
                )),
                
                const SizedBox(height: 24),
                
                Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Get.snackbar(
                        "Terms & Conditions", 
                        "Full terms and conditions are not available in this demo.",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        margin: const EdgeInsets.all(16),
                        borderRadius: 16,
                      );
                    },
                    child: Text(
                      'By signing up, you agree to our Terms and Conditions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
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
