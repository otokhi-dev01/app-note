import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/decorative_background.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecorativeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                const SizedBox(height: 20),
                
                // Logo Section with Animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Welcome Text with Animation
                _buildAnimatedSlide(
                  delay: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join us and start capturing clarity today.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Form Section
                _buildAnimatedSlide(
                  delay: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'Full Name',
                        controller: controller.fullNameController,
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'Phone Number',
                        controller: controller.phoneController,
                        hint: 'Enter your phone',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      Obx(() => CustomTextField(
                        label: 'Password',
                        controller: controller.passwordController,
                        hint: 'Create a password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: controller.obscurePassword.value,
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value 
                              ? Icons.visibility_off_outlined 
                              : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textPlaceholder,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      )),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Action Buttons
                _buildAnimatedSlide(
                  delay: 600,
                  child: Column(
                    children: [
                      Obx(() => AppButton(
                        text: 'Register',
                        isLoading: controller.isLoading.value,
                        onPressed: controller.register,
                        icon: Icons.person_add_alt_1_rounded,
                      )),
                      const SizedBox(height: 32),
                      
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
                          ),
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSlide({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
