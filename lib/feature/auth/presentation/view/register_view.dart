import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/auth/presentation/widgets/auth_brand_header_widgets.dart';
import 'package:note_app/feature/auth/presentation/widgets/auth_message_box_widget.dart';
import 'package:note_app/feature/auth/presentation/widgets/auth_primary_button_widget.dart';
import 'package:note_app/feature/auth/presentation/widgets/auth_text_field_widget.dart';
import '../controller/register_controller.dart';
import '../widgets/auth_background_widget.dart';
import '../widgets/auth_glass_card_widget.dart';

class RegisterView
    extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus
              ?.unfocus();
        },
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: AuthBackgroundWidget(),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _RegisterTopBar(
                    onBack: controller.openLogin,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        10,
                        20,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                          const BoxConstraints(
                            maxWidth: 460,
                          ),
                          child: AuthGlassCardWidget(
                            child: AutofillGroup(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .stretch,
                                children: <Widget>[
                              AuthBrandHeaderWidgets(
                              imagePath:
                              'assets/images/piisiit_note_logo.png',
                                title: 'piisiit_note'.tr,
                                subtitle: 'welcome_back'.tr,
                                description: 'sign_in_description'.tr,
                              ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  AuthTextFieldWidget(
                                    controller: controller
                                        .fullNameController,
                                    label: 'Full name',
                                    hintText:
                                    'Enter your full name',
                                    icon:
                                    CupertinoIcons
                                        .person,
                                    keyboardType:
                                    TextInputType
                                        .name,
                                    textInputAction:
                                    TextInputAction
                                        .next,
                                    autofillHints:
                                    const <String>[
                                      AutofillHints.name,
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  AuthTextFieldWidget(
                                    controller: controller
                                        .phoneController,
                                    label: 'phone_number'.tr,
                                    hintText: 'enter_phone_number'.tr,
                                    icon:
                                    CupertinoIcons
                                        .phone,
                                    keyboardType:
                                    TextInputType
                                        .phone,
                                    textInputAction:
                                    TextInputAction
                                        .next,
                                    autofillHints:
                                    const <String>[
                                      AutofillHints
                                          .telephoneNumber,
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Obx(
                                        () => AuthTextFieldWidget(
                                      controller: controller
                                          .passwordController,
                                      label: 'Password',
                                      hintText:
                                      'Create a secure password',
                                      icon:
                                      CupertinoIcons
                                          .lock,
                                      obscureText:
                                      controller
                                          .obscurePassword
                                          .value,
                                      textInputAction:
                                      TextInputAction
                                          .next,
                                      autofillHints:
                                      const <
                                          String>[
                                        AutofillHints
                                            .newPassword,
                                      ],
                                      suffix:
                                      _VisibilityButton(
                                        isObscured: controller
                                            .obscurePassword
                                            .value,
                                        onPressed: controller
                                            .togglePasswordVisibility,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Obx(
                                        () => AuthTextFieldWidget(
                                      controller: controller
                                          .confirmPasswordController,
                                      label:
                                      'Confirm password',
                                      hintText:
                                      'Enter your password again',
                                      icon:
                                      CupertinoIcons
                                          .lock_shield,
                                      obscureText:
                                      controller
                                          .obscureConfirmPassword
                                          .value,
                                      textInputAction:
                                      TextInputAction
                                          .done,
                                      autofillHints:
                                      const <
                                          String>[
                                        AutofillHints
                                            .newPassword,
                                      ],
                                      onSubmitted: (_) {
                                        if (!controller
                                            .isLoading
                                            .value) {
                                          controller
                                              .register();
                                        }
                                      },
                                      suffix:
                                      _VisibilityButton(
                                        isObscured: controller
                                            .obscureConfirmPassword
                                            .value,
                                        onPressed: controller
                                            .toggleConfirmPasswordVisibility,
                                      ),
                                    ),
                                  ),
                                  Obx(() {
                                    final String error =
                                    controller
                                        .errorMessage
                                        .value
                                        .trim();

                                    if (error.isEmpty) {
                                      return const SizedBox
                                          .shrink();
                                    }

                                    return Padding(
                                      padding:
                                      const EdgeInsets
                                          .only(
                                        top: 14,
                                      ),
                                      child:
                                      AuthMessageBoxWidget(
                                        message: error,
                                      ),
                                    );
                                  }),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Obx(
                                        () =>
                                        AuthPrimaryButtonWidget(
                                          label:
                                          'Create Account',
                                          isLoading:
                                          controller
                                              .isLoading
                                              .value,
                                          onPressed:
                                          controller
                                              .register,
                                        ),
                                  ),
                                  const SizedBox(
                                    height: 19,
                                  ),
                                  _LoginLink(
                                    onPressed:
                                    controller
                                        .openLogin,
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  const _RegisterSecurityNotice(),
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

class _RegisterTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _RegisterTopBar({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        6,
        14,
        4,
      ),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                colorScheme.surface.withValues(
                  alpha: 0.68,
                ),
                border: Border.all(
                  color: colorScheme.outlineVariant
                      .withValues(alpha: 0.32),
                ),
              ),
              child: Icon(
                CupertinoIcons.back,
                size: 21,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  final bool isObscured;
  final VoidCallback onPressed;

  const _VisibilityButton({
    required this.isObscured,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Icon(
        isObscured
            ? CupertinoIcons.eye
            : CupertinoIcons.eye_slash,
        size: 21,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  final VoidCallback onPressed;

  const _LoginLink({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Already have an account?',
          style: theme.textTheme.bodyMedium
              ?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        CupertinoButton(
          padding:
          const EdgeInsets.only(left: 6),
          onPressed: onPressed,
          child: Text(
            'Sign In',
            style: theme.textTheme.bodyMedium
                ?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterSecurityNotice
    extends StatelessWidget {
  const _RegisterSecurityNotice();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          CupertinoIcons.lock_shield,
          size: 15,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Your account information is securely protected',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
              color:
              colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}