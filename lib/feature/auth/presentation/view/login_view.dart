import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';
import '../widgets/auth_background_widget.dart';
import '../widgets/auth_brand_header_widgets.dart';
import '../widgets/auth_glass_card_widget.dart';
import '../widgets/auth_message_box_widget.dart';
import '../widgets/auth_primary_button_widget.dart';
import '../widgets/auth_text_field_widget.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

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
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    32,
                    20,
                    32,
                  ),
                  child: ConstrainedBox(
                    constraints:
                    const BoxConstraints(
                      maxWidth: 440,
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
                            const SizedBox(height: 32),
                            AuthTextFieldWidget(
                              controller: controller
                                  .phoneController,
                              label: 'phone_number'.tr,
                              hintText: 'enter_phone_number'.tr,
                              icon:
                              CupertinoIcons.phone,
                              keyboardType:
                              TextInputType.phone,
                              textInputAction:
                              TextInputAction.next,
                              autofillHints: const <
                                  String>[
                                AutofillHints
                                    .telephoneNumber,
                              ],
                            ),
                            const SizedBox(height: 16),
                            Obx(
                                  () => AuthTextFieldWidget(
                                controller: controller
                                    .passwordController,
                                label: 'Password',
                                hintText:
                                'Enter your password',
                                icon:
                                CupertinoIcons.lock,
                                obscureText: controller
                                    .obscurePassword
                                    .value,
                                textInputAction:
                                TextInputAction.done,
                                autofillHints: const <
                                    String>[
                                  AutofillHints
                                      .password,
                                ],
                                onSubmitted: (_) {
                                  if (!controller
                                      .isLoading.value) {
                                    controller.login();
                                  }
                                },
                                suffix:
                                CupertinoButton(
                                  padding:
                                  EdgeInsets.zero,
                                  onPressed: controller
                                      .togglePasswordVisibility,
                                  child: Icon(
                                    controller
                                        .obscurePassword
                                        .value
                                        ? CupertinoIcons
                                        .eye
                                        : CupertinoIcons
                                        .eye_slash,
                                    size: 21,
                                    color: Theme.of(
                                      context,
                                    )
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            Obx(() {
                              final String success =
                              controller
                                  .successMessage
                                  .value
                                  .trim();

                              if (success.isEmpty) {
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
                                  message: success,
                                  isError: false,
                                ),
                              );
                            }),
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
                            const SizedBox(height: 20),
                            Obx(
                                  () => AuthPrimaryButtonWidget(
                                    label: 'sign_in'.tr,
                                isLoading: controller
                                    .isLoading.value,
                                onPressed:
                                controller.login,
                              ),
                            ),
                            const SizedBox(height: 19),
                            _CreateAccountLink(
                              onPressed:
                              controller.openRegister,
                            ),
                            const SizedBox(height: 15),
                            const _SecurityNotice(),
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
    );
  }
}

class _CreateAccountLink
    extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateAccountLink({
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
          'Don’t have an account?'.tr,
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
            'Create Account'.tr,
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

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

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
            'Your account is securely protected',
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