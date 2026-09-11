import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/utils/validators.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/app_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});
  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  static const int _maxPhoneLength = 16;
  late final TextEditingController _phoneController;
  late final Future<bool> Function(String phone) _onSubmit;
  bool _isSubmitting = false;
  String? _errorText;
  String get _phone => _phoneController.text.trim();
  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    final values = arguments is Map ? arguments : {};
    _onSubmit = values['onSubmit'] is Future<bool> Function(String)
        ? values['onSubmit'] as Future<bool> Function(String)
        : (_) async => false;
    _phoneController = TextEditingController(
      text: values['initialPhone']?.toString() ?? '',
    )..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _phoneController
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() => _errorText = null);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final invalid = Validators.phone(_phone);
    if (invalid != null) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _errorText = invalid);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    final sent = await _onSubmit(_phone);
    if (!mounted) return;
    if (sent) {
      Get.back();
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return PopScope(
      canPop: !_isSubmitting,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          body: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: BouncingScrollPhysics(),
            slivers: [
              AppScreenSliverAppBar(
                title: 'forgot_password_title'.tr,
                centerTitle: true,
                leading: CustomGlassButton(
                  semanticLabel: MaterialLocalizations.of(
                    context,
                  ).backButtonTooltip,
                  onPressed: _isSubmitting ? null : () => Get.back(),
                  width: 44,
                  height: 44,
                  shape: GlassShape.circle,
                  blur: 10,
                  opacity: 0.15,
                  thickness: 8,
                  glassColor: null,
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.back, size: 23),
                ),
              ),
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 620),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        MediaQuery.viewInsetsOf(context).bottom + 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: AppLogo(height: 78)
                                .animate()
                                .scale(
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                  begin: const Offset(0.9, 0.9),
                                  end: const Offset(1, 1),
                                )
                                .fadeIn(duration: 400.ms),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              "forgot_password_title".tr,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'forgot_password_desc'.tr,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.45,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomGlassContainer(
                            borderRadius: 30,
                            blur: 35,
                            opacity: 0.1,
                            thickness: 15,
                            showGlow: true,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 24),
                                    decoration: BoxDecoration(
                                      color: theme.dividerColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                _buildPhoneField(context),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting || _phone.isEmpty
                                  ? null
                                  : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'send_reset_request'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
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
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _phoneController,
        autofocus: true,
        enabled: !_isSubmitting,
        maxLength: _maxPhoneLength,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'username_email_phone_hint'.tr,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          errorText: _errorText,
          counterText: '',
          prefixIcon: Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
