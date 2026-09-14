import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
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
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            _buildBackdrop(context),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: LanguageToggleButton(),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 460,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    0,
                                    24,
                                    24,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildHeader(context),
                                      const SizedBox(height: 28),
                                      _buildFormCard(context),
                                      const SizedBox(height: 22),
                                      _buildGuestButton(context),
                                      const SizedBox(height: 10),
                                      Text(
                                        'login_guest_description'.tr,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ).animate().fadeIn(delay: 500.ms),
                                      const SizedBox(height: 22),
                                      _buildRegisterRow(context),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdrop(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -100,
            child: _glow(accent, 320, isDark ? 0.30 : 0.20),
          ),
          Positioned(
            bottom: -150,
            left: -120,
            child: _glow(accent, 340, isDark ? 0.22 : 0.14),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const AppLogo(height: 84, showGlow: true)
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
            )
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 22),
        Text(
              'welcome_piisiit'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 29,
                letterSpacing: -0.5,
                color: theme.colorScheme.primary,
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        Text(
          'sign_in_subtitle'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    final theme = Theme.of(context);

    return CustomGlassContainer(
          borderRadius: 28,
          blur: 35,
          opacity: 0.12,
          thickness: 16,
          showGlow: true,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomGlassTextField(
                    controller: controller.accountController,
                    placeholder: 'username_email_phone_hint'.tr,
                    height: 56,
                    borderRadius: 18,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(
                      CupertinoIcons.person_fill,
                      size: 20,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    textStyle: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    placeholderStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Obx(
                    () => CustomGlassTextField(
                      controller: controller.passwordController,
                      placeholder: 'password_label'.tr,
                      obscureText: !controller.isPasswordVisible.value,
                      height: 56,
                      borderRadius: 18,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.login(),
                      prefixIcon: Icon(
                        CupertinoIcons.lock_fill,
                        size: 20,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      suffixIcon: Icon(
                        controller.isPasswordVisible.value
                            ? CupertinoIcons.eye_slash_fill
                            : CupertinoIcons.eye_fill,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onSuffixTap: controller.togglePasswordVisibility,
                      textStyle: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      placeholderStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(-6, 0),
                        child: Obx(
                          () => Checkbox(
                            value: controller.rememberMe.value,
                            onChanged: (_) => controller.toggleRememberMe(),
                            activeColor: theme.colorScheme.primary,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.toggleRememberMe,
                        child: Text(
                          'remember_me'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: controller.forgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'forgot_password'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => CustomGlassButton(
                      semanticLabel: 'sign_in_button'.tr,
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.login,
                      minHeight: 56,
                      borderRadius: 26,
                      style: lg.GlassButtonStyle.prominent,
                      glassColor: theme.colorScheme.primary,
                      glowColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      child: controller.isLoading.value
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'sign_in_button'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 380.ms, duration: 450.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildGuestButton(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: CustomGlassButton(
          semanticLabel: 'onboarding_continue_guest'.tr,
          onPressed: controller.isLoading.value
              ? null
              : controller.continueWithoutAccount,
          minHeight: 52,
          borderRadius: 26,
          foregroundColor: AppTheme.folderPink,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'onboarding_continue_guest'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  Widget _buildRegisterRow(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'login_no_account'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: () => Get.toNamed(Routes.REGISTER),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 5),
          ),
          child: Text(
            'register_link'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 550.ms);
  }
}
