import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/features/settings/presentation/controllers/account_controller.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// Full-screen destructive account flow shared by the drawer, Profile, and
/// Account screens.
class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  AccountController get _controller => Get.find<AccountController>();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          slivers: [
            AppScreenSliverAppBar(
              title: 'delete_account_title'.tr,
              centerTitle: true,
              leading: CustomGlassButton(
                semanticLabel: MaterialLocalizations.of(
                  context,
                ).backButtonTooltip,
                onPressed: () => Get.back(),
                width: 44,
                height: 44,
                shape: GlassShape.circle,
                blur: 10,
                opacity: 0.15,
                thickness: 8,
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.chevron_left, size: 23),
              ),
            ),
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      28,
                      20,
                      MediaQuery.viewInsetsOf(context).bottom + 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildWarningCard(context),
                        const SizedBox(height: 24),
                        Text(
                          'account_confirm_password_title'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'account_confirm_password_subtitle'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CustomGlassTextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          placeholder: 'password_hint'.tr,
                          textInputAction: TextInputAction.done,
                          textStyle: theme.textTheme.bodyLarge,
                          onSubmitted: (_) => _submit(),
                          suffixIcon: Icon(
                            _obscurePassword
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                          ),
                          onSuffixTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Obx(
                          () => CustomGlassButton(
                            semanticLabel: 'account_delete_button'.tr,
                            onPressed: _controller.isDeleting.value
                                ? null
                                : _submit,
                            minHeight: 52,
                            borderRadius: 18,
                            glassColor: Colors.red.withValues(alpha: 0.88),
                            foregroundColor: Colors.white,
                            child: _controller.isDeleting.value
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'account_delete_button'.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context) {
    final theme = Theme.of(context);

    return CustomGlassContainer(
      borderRadius: 24,
      blur: 20,
      opacity: 0.12,
      thickness: 8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.red,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'account_delete_confirm_title'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'account_delete_account_desc'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    _controller.deleteAccount(_passwordController.text);
  }
}
