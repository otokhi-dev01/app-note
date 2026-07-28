import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/decorative_background.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/language_picker_button.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecorativeBackground(
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    LiquidGlassContainer(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo Section with Animation
                          _buildAnimatedSlide(
                            delay: 0,
                            child: Center(
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: Image.asset(
                                      'assets/icons/logo_icon.png',
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'OTOKHI NOTES',
                                    style: TextStyle(
                                      fontSize: 20,
                                      letterSpacing: 6,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Welcome Text with Animation
                          _buildAnimatedSlide(
                            delay: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'create_account'.tr,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'sign_up_subtitle'.tr,
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
                                Obx(() => CustomTextField(
                                  label: 'full_name'.tr,
                                  controller: controller.fullNameController,
                                  hint: 'enter_full_name'.tr,
                                  prefixIcon: Icons.person_outline_rounded,
                                  isError: controller.hasError.value,
                                )),
                                const SizedBox(height: 20),
                                Obx(() => CustomTextField(
                                  label: 'phone_number'.tr,
                                  controller: controller.phoneController,
                                  hint: 'enter_phone'.tr,
                                  prefixIcon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  isError: controller.hasError.value,
                                )),
                                const SizedBox(height: 20),
                                Obx(() => CustomTextField(
                                  label: 'password'.tr,
                                  controller: controller.passwordController,
                                  hint: 'create_password'.tr,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: controller.obscurePassword.value,
                                  isError: controller.hasError.value,
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
                                  text: 'register'.tr,
                                  isLoading: controller.isLoading.value,
                                  onPressed: controller.register,
                                  icon: Icons.person_add_alt_1_rounded,
                                )),
                              ],
                            ),
                          ),
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
                            'already_have_account'.tr,
                            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
                          ),
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Text(
                              'sign_in'.tr,
                              style: const TextStyle(
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                    const LanguagePickerButton(),
                  ],
                ),
              ),
            ),
          ],
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
