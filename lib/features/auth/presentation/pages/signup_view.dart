import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/core/network/api_endpoints.dart';
import 'package:notes/core/presentation/animations/fade_in_widget.dart';
import 'package:notes/features/auth/presentation/controllers/signup_controller.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.left_chevron,
                color: AppColors.orange,
                size: 22,
              ),
              Text(
                'Sign In',
                style: TextStyle(color: AppColors.orange, fontSize: 17),
              ),
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
                          color: theme.shadowColor.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.3
                                : 0.06,
                          ),
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
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create an account with the phone number you will use to sign in.',
                  style: TextStyle(
                    fontSize: 17,
                    color: colors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 40),

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
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CupertinoTextField(
                        controller: controller.phoneController,
                        placeholder: 'Phone number',
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                          LengthLimitingTextInputFormatter(
                            ApiEndpoints.maximumPhoneLength,
                          ),
                        ],
                        padding: const EdgeInsets.all(16),
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
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        enableSuggestions: false,
                        autocorrect: false,
                        onSubmitted: (_) => controller.signup(),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            ApiEndpoints.maximumPasswordLength,
                          ),
                        ],
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(),
                        placeholderStyle: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                        style: TextStyle(fontSize: 17, color: colors.onSurface),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.signup,
                      child: controller.isLoading.value
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Text(
                    'Password must contain at least '
                    '${ApiEndpoints.minimumPasswordLength} characters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
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
