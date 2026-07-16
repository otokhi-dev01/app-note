import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/core/network/api_endpoints.dart';
import 'package:notes/core/presentation/animations/fade_in_widget.dart';
import 'package:notes/features/auth/presentation/controllers/signup_controller.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.back(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.left_chevron,
                color: colors.primary,
                size: 21,
              ),
              const SizedBox(width: 2),
              Text(
                'Sign In',
                style: TextStyle(color: colors.primary, fontSize: 17),
              ),
            ],
          ),
        ),
      ),
      body: _AuthBackdrop(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: FadeInWidget(
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _AppIcon(
                          shadowColor: colors.primary.withValues(
                            alpha: isDark ? 0.2 : 0.16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      Text(
                        'Create Account',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                          height: 1.05,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create an account with the phone number you will use to sign in.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 30),
                      AutofillGroup(
                        child: _InsetForm(
                          children: [
                            CupertinoTextField(
                              controller: controller.phoneController,
                              placeholder: 'Phone number',
                              keyboardType: TextInputType.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+]'),
                                ),
                                LengthLimitingTextInputFormatter(
                                  ApiEndpoints.maximumPhoneLength,
                                ),
                              ],
                              prefix: _FieldIcon(
                                icon: CupertinoIcons.phone_fill,
                                color: colors.primary,
                              ),
                              padding: const EdgeInsets.fromLTRB(0, 18, 16, 18),
                              decoration: const BoxDecoration(),
                              placeholderStyle: TextStyle(
                                color: colors.onSurfaceVariant,
                              ),
                              style: TextStyle(
                                fontSize: 17,
                                color: colors.onSurface,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 52),
                              child: Divider(
                                height: 0.5,
                                thickness: 0.5,
                                color: colors.outlineVariant,
                              ),
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
                              prefix: _FieldIcon(
                                icon: CupertinoIcons.lock_fill,
                                color: colors.primary,
                              ),
                              padding: const EdgeInsets.fromLTRB(0, 18, 16, 18),
                              decoration: const BoxDecoration(),
                              placeholderStyle: TextStyle(
                                color: colors.onSurfaceVariant,
                              ),
                              style: TextStyle(
                                fontSize: 17,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PasswordHint(
                        accentColor: colors.primary,
                        textColor: colors.onSurfaceVariant,
                        backgroundColor: colors.surfaceContainerHigh.withValues(
                          alpha: isDark ? 0.62 : 0.58,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: colors.primary,
                            disabledColor: colors.primary.withValues(
                              alpha: 0.42,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.signup,
                            child: controller.isLoading.value
                                ? CupertinoActivityIndicator(
                                    color: colors.onPrimary,
                                  )
                                : Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: colors.onPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
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
          ),
        ),
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = theme.scaffoldBackgroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background,
            Color.alphaBlend(
              colors.primary.withValues(alpha: 0.055),
              background,
            ),
            background,
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: child,
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.shadowColor});

  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Image.asset(
          'assets/icons/notes_v26.png',
          width: 70,
          height: 70,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _InsetForm extends StatelessWidget {
  const _InsetForm({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.9 : 0.96,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.72),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.18 : 0.06,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _FieldIcon extends StatelessWidget {
  const _FieldIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 17, right: 13),
      child: Icon(icon, size: 19, color: color),
    );
  }
}

class _PasswordHint extends StatelessWidget {
  const _PasswordHint({
    required this.accentColor,
    required this.textColor,
    required this.backgroundColor,
  });

  final Color accentColor;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.checkmark_shield_fill,
            size: 17,
            color: accentColor,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Password must contain at least '
              '${ApiEndpoints.minimumPasswordLength} characters.',
              style: TextStyle(color: textColor, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
