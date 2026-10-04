import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_toggle_button.dart';
import 'package:Note/features/auth/presentation/controllers/registration_controller.dart';
import 'package:Note/shared/widgets/app_logo.dart';
import 'package:Note/features/auth/presentation/widgets/password_otp_step.dart';
import 'package:Note/features/auth/presentation/widgets/account_input_field.dart';
import 'package:Note/features/auth/presentation/widgets/registration_success.dart';

class RegisterScreen extends GetView<RegistrationController> {
  const RegisterScreen({super.key});

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
              child: Obx(() {
                if (controller.completed.value) {
                  return RegistrationSuccess(
                    emailVerified: controller.completedEmailVerified,
                    account: controller.completedAccount,
                    onDone: controller.finishRegistration,
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomGlassButton(
                            semanticLabel: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            onPressed: () {
                              if (controller.isLoading.value) return;
                              if ((controller.isOtpStep.value ||
                                      controller.isEmailStep.value) &&
                                  !controller.accountCreated.value) {
                                controller.editDetails();
                              } else {
                                Get.back();
                              }
                            },
                            width: 44,
                            height: 44,
                            shape: GlassShape.circle,
                            blur: 10,
                            opacity: 0.15,
                            thickness: 8,
                            foregroundColor: theme.colorScheme.onSurface,
                            padding: EdgeInsets.zero,
                            child: const Icon(
                              CupertinoIcons.chevron_left,
                              size: 23,
                            ),
                          ),
                          const LanguageToggleButton(),
                        ],
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildHeader(context),
                                        const SizedBox(height: 28),
                                        _buildFormCard(context),
                                        // const SizedBox(height: 10),
                                        _buildLoginRow(context),
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
                );
              }),
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
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
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
              'register_create_account'.tr,
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
          'register_subtitle'.tr,
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
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
              child: Obx(
                () => AbsorbPointer(
                  absorbing: controller.isLoading.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (controller.isOtpStep.value) ...[
                        Text(
                          controller.accountCreated.value
                              ? 'register_profile_title'.tr
                              : 'register_otp_title'.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.accountCreated.value
                              ? 'register_profile_description'.tr
                              : 'register_otp_description'.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.verificationEmail.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 24),
                        if (controller.accountCreated.value) ...[
                          if (controller.canEditProfileAccount)
                            AccountInputField(
                              controller: controller.accountController,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => controller.register(),
                            ),
                        ] else
                          OtpCodeField(
                            controller: controller.otpController,
                            enabled: !controller.isLoading.value,
                            hasError: controller.error.value.isNotEmpty,
                            onSubmitted: controller.verifyAndRegister,
                            onChanged: (_) => controller.error.value = '',
                          ),
                      ] else if (controller.isEmailStep.value) ...[
                        Text(
                          'register_otp_title'.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'register_verification_email_description'.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        CustomGlassTextField(
                          controller: controller.emailController,
                          placeholder: 'register_email_label'.tr,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => controller.register(),
                          prefixIcon: Icon(
                            CupertinoIcons.mail,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ] else ...[
                        AccountInputField(
                          controller: controller.accountController,
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => CustomGlassTextField(
                            controller: controller.passwordController,
                            placeholder: 'password_label'.tr,
                            obscureText: !controller.isPasswordVisible.value,
                            height: 56,
                            borderRadius: 20,
                            textInputAction: TextInputAction.next,
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
                            placeholderStyle: theme.textTheme.bodyMedium
                                ?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => CustomGlassTextField(
                            controller: controller.confirmPasswordController,
                            placeholder: 'confirm_password_label'.tr,
                            obscureText:
                                !controller.isConfirmPasswordVisible.value,
                            height: 56,
                            borderRadius: 20,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => controller.register(),
                            prefixIcon: Icon(
                              CupertinoIcons.lock_fill,
                              size: 20,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            suffixIcon: Icon(
                              controller.isConfirmPasswordVisible.value
                                  ? CupertinoIcons.eye_slash_fill
                                  : CupertinoIcons.eye_fill,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onSuffixTap:
                                controller.toggleConfirmPasswordVisibility,
                            textStyle: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            placeholderStyle: theme.textTheme.bodyMedium
                                ?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Obx(
                        () => controller.error.value.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    controller.error.value,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      Obx(
                        () => CustomGlassButton(
                          semanticLabel: _submitLabel(),
                          onPressed:
                              controller.isLoading.value ||
                                  controller.retryIn.value > 0
                              ? null
                              : controller.register,
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
                                  controller.retryIn.value > 0
                                      ? 'register_retry_countdown'.trParams({
                                          'seconds':
                                              '${controller.retryIn.value}',
                                        })
                                      : _submitLabel(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                        ),
                      ),
                      if ((controller.isOtpStep.value ||
                              controller.isEmailStep.value) &&
                          !controller.accountCreated.value) ...[
                        const SizedBox(height: 12),
                        if (controller.isOtpStep.value)
                          TextButton(
                            onPressed:
                                controller.resendIn.value > 0 ||
                                    controller.retryIn.value > 0 ||
                                    controller.isLoading.value
                                ? null
                                : controller.resendOtp,
                            child: Text(
                              controller.resendIn.value > 0
                                  ? 'register_resend_countdown'.trParams({
                                      'seconds': '${controller.resendIn.value}',
                                    })
                                  : 'register_resend_otp'.tr,
                            ),
                          ),
                        TextButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.editDetails,
                          child: Text('register_edit_details'.tr),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 380.ms, duration: 450.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  String _submitLabel() {
    if (controller.accountCreated.value) return 'register_finish'.tr;
    if (controller.isOtpStep.value) return 'register_verify_create'.tr;
    if (controller.isEmailStep.value) return 'register_send_code'.tr;
    return 'sign_up_button'.tr;
  }

  Widget _buildLoginRow(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "register_have_account".tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 5),
          ),
          child: Text(
            "login_link".tr,
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

// Preserve existing imports while the route uses the dedicated registration controller.
typedef RegisterView = RegisterScreen;
