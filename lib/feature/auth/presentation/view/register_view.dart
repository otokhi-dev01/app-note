import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/register_controller.dart';
import '../widgets/auth_background_widget.dart';
import '../widgets/auth_brand_header_widget.dart';
import '../widgets/auth_glass_card_widget.dart';
import '../widgets/auth_message_box_widget.dart';
import '../widgets/auth_navigation_link_widget.dart';
import '../widgets/auth_password_visibility_button_widget.dart';
import '../widgets/auth_primary_button_widget.dart';
import '../widgets/auth_security_notice_widget.dart';
import '../widgets/auth_text_field_widget.dart';
import '../widgets/register_top_bar_widget.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: AuthBackgroundWidget()),
            SafeArea(
              child: Column(
                children: <Widget>[
                  RegisterTopBarWidget(onBack: controller.openLogin),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: AuthGlassCardWidget(
                            child: AutofillGroup(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  AuthBrandHeaderWidget(
                                    imagePath:
                                        'assets/images/piisiit_note_logo.png',
                                    title: 'piisiit_note'.tr,
                                    subtitle: 'Create your account',
                                    description:
                                        'Register with your phone number to get started.',
                                  ),
                                  const SizedBox(height: 30),
                                  AuthTextFieldWidget(
                                    controller: controller.phoneController,
                                    label: 'phone_number'.tr,
                                    hintText: 'enter_phone_number'.tr,
                                    icon: CupertinoIcons.phone,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const <String>[
                                      AutofillHints.telephoneNumber,
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Obx(
                                    () => AuthTextFieldWidget(
                                      controller: controller.passwordController,
                                      label: 'Password',
                                      hintText: 'Create a secure password',
                                      icon: CupertinoIcons.lock,
                                      obscureText:
                                          controller.obscurePassword.value,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const <String>[
                                        AutofillHints.newPassword,
                                      ],
                                      suffix:
                                          AuthPasswordVisibilityButtonWidget(
                                            isObscured: controller
                                                .obscurePassword
                                                .value,
                                            onPressed: controller
                                                .togglePasswordVisibility,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Obx(
                                    () => AuthTextFieldWidget(
                                      controller:
                                          controller.confirmPasswordController,
                                      label: 'Confirm password',
                                      hintText: 'Enter your password again',
                                      icon: CupertinoIcons.lock_shield,
                                      obscureText: controller
                                          .obscureConfirmPassword
                                          .value,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const <String>[
                                        AutofillHints.newPassword,
                                      ],
                                      onSubmitted: (_) {
                                        if (!controller.isLoading.value) {
                                          controller.register();
                                        }
                                      },
                                      suffix: AuthPasswordVisibilityButtonWidget(
                                        isObscured: controller
                                            .obscureConfirmPassword
                                            .value,
                                        onPressed: controller
                                            .toggleConfirmPasswordVisibility,
                                      ),
                                    ),
                                  ),
                                  Obx(() {
                                    final String error = controller
                                        .errorMessage
                                        .value
                                        .trim();

                                    if (error.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: AuthMessageBoxWidget(
                                        message: error,
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 20),
                                  Obx(
                                    () => AuthPrimaryButtonWidget(
                                      label: 'Create Account',
                                      isLoading: controller.isLoading.value,
                                      onPressed: controller.register,
                                    ),
                                  ),
                                  const SizedBox(height: 19),
                                  AuthNavigationLinkWidget(
                                    prompt: 'Already have an account?',
                                    actionLabel: 'Sign In',
                                    onPressed: controller.openLogin,
                                  ),
                                  const SizedBox(height: 15),
                                  const AuthSecurityNoticeWidget(
                                    message:
                                        'Your account information is securely protected',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
}
