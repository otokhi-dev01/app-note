import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/decorative_background.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecorativeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
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
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'PHOTOKIT NOTES',
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 56),
                // Welcome Text with Animation
                _buildAnimatedSlide(
                  delay: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to sync your ideas and notes.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Form Section
                _buildAnimatedSlide(
                  delay: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'Phone Number',
                        controller: controller.phoneController,
                        hint: 'Enter your phone',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      Obx(() => CustomTextField(
                        label: 'Password',
                        controller: controller.passwordController,
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Action Buttons
                _buildAnimatedSlide(
                  delay: 600,
                  child: Column(
                    children: [
                      Obx(() => AppButton(
                        text: 'Sign In',
                        isLoading: controller.isLoading.value,
                        onPressed: controller.login,
                        icon: Icons.login_rounded,
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Footer
                _buildAnimatedSlide(
                  delay: 800,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.register),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
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
