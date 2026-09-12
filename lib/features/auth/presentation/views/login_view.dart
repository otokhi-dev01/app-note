import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_toggle_button.dart';
import 'package:Note/features/auth/presentation/controllers/auth_controller.dart';
import 'package:Note/shared/widgets/app_logo.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: LanguageToggleButton(),
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppLogo(height: 78)
                        .animate()
                        .scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                          begin: Offset(0.9, 0.9),
                          end: Offset(1, 1),
                        )
                        .fadeIn(duration: 400.ms),
                    SizedBox(height: 20),
                    Text(
                          "welcome_piisiit".tr,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                            color: theme.colorScheme.primary,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                    SizedBox(height: 8),
                    Text(
                      "sign_in_subtitle".tr,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18),
                    ).animate().fadeIn(delay: 300.ms),
                    SizedBox(height: 15),
                    // Login Card
                    CustomGlassContainer(
                      borderRadius: 30,
                      blur: 35,
                      opacity: 0.1,
                      thickness: 15,
                      showGlow: true,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  margin: EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              _buildTextField(
                                context,
                                controller: controller.accountController,
                                hint: "username_email_phone_hint".tr,
                                icon: Icons.person,
                              ),
                              SizedBox(height: 20),
                              Obx(
                                () => _buildTextField(
                                  context,
                                  controller: controller.passwordController,
                                  hint: "password_label".tr,
                                  icon: Icons.lock,
                                  isPassword:
                                      !controller.isPasswordVisible.value,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      controller.isPasswordVisible.value
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    onPressed:
                                        controller.togglePasswordVisibility,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Divider(height: 1),
                              Row(
                                children: [
                                  Obx(
                                    () => Checkbox(
                                      value: controller.rememberMe.value,
                                      onChanged: (_) =>
                                          controller.toggleRememberMe(),
                                      activeColor: AppTheme.folderPink,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: controller.toggleRememberMe,
                                    child: Text(
                                      "remember_me".tr,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  Spacer(),
                                  TextButton(
                                    onPressed: controller.forgotPassword,
                                    child: Text(
                                      "forgot_password".tr,
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              Obx(
                                () => SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: controller.isLoading.value
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "sign_in_button".tr,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.continueWithoutAccount,
                          icon: const Icon(Icons.person_outline_rounded),
                          label: Text('onboarding_continue_guest'.tr),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.folderPink,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'login_guest_description'.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "login_no_account".tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed(Routes.REGISTER),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: EdgeInsets.symmetric(horizontal: 5),
                          ),
                          child: Text(
                            "register_link".tr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required dynamic icon,
    bool isPassword = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: false,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: icon is IconData
              ? Icon(
                  icon,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  size: 22,
                )
              : Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: FaIcon(
                    icon,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
