import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/core/network/api_endpoints.dart';
import 'package:notes/core/presentation/animations/fade_in_widget.dart';
import 'package:notes/core/presentation/brand/app_brand.dart';
import 'package:notes/core/presentation/widgets/liquid_glass_sliver_app_bar.dart';
import 'package:notes/features/auth/presentation/controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return _AuthBackdrop(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            sliver: SliverToBoxAdapter(
              child: LiquidGlassSliverAppBar(
                height: 60,
                blur: 22,
                title: const SizedBox.shrink(),
                leading: (c) => const SizedBox.shrink(),
                actions: const [],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: SafeArea(
              top: false,
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: FadeInWidget(
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: const _AppIcon()),
                          const SizedBox(height: 42),
                          Text(
                            'Sign In',
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
                            'Enter your phone number and password to access your notes.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
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
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    18,
                                    16,
                                    18,
                                  ),
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
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  onSubmitted: (_) => controller.login(),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      ApiEndpoints.maximumPasswordLength,
                                    ),
                                  ],
                                  prefix: _FieldIcon(
                                    icon: CupertinoIcons.lock_fill,
                                    color: colors.primary,
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    18,
                                    16,
                                    18,
                                  ),
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
                                    : controller.login,
                                child: controller.isLoading.value
                                    ? CupertinoActivityIndicator(
                                        color: colors.onPrimary,
                                      )
                                    : Text(
                                        'Sign In',
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
                          const SizedBox(height: 28),
                          Center(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              onPressed: () => Get.toNamed(AppRoutes.signup),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Don\'t have an account? ',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: _PrivacyBadge(
                              iconColor: colors.onSurfaceVariant,
                              textColor: colors.onSurfaceVariant,
                              backgroundColor: colors.surfaceContainerHigh
                                  .withValues(alpha: isDark ? 0.72 : 0.64),
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
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppBrandBackdrop(child: child);
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return const AppBrandLogo(height: 112, borderRadius: 24);
  }
}

class _InsetForm extends StatelessWidget {
  const _InsetForm({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppGlassSurface(
      borderRadius: BorderRadius.circular(22),
      opacity: theme.brightness == Brightness.dark ? .72 : .78,
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

class _PrivacyBadge extends StatelessWidget {
  const _PrivacyBadge({
    required this.iconColor,
    required this.textColor,
    required this.backgroundColor,
  });

  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.lock_shield_fill, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Text(
            'Private and secure',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
