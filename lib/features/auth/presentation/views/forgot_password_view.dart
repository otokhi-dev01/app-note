import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/core/utils/validators.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  static const _maxPhoneLength = 16;

  late final TextEditingController _phoneController;
  late final Future<bool> Function(String phone) _onSubmit;
  bool _isSubmitting = false;
  String? _errorText;

  String get _phone => _phoneController.text.trim();

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    final values = arguments is Map ? arguments : const {};
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
            physics: const BouncingScrollPhysics(),
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
                        18,
                        20,
                        MediaQuery.viewInsetsOf(context).bottom + 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'forgot_password_desc'.tr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomGlassContainer(
                            borderRadius: 22,
                            blur: 20,
                            opacity: 0.12,
                            thickness: 8,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'phone_number_label'.tr,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildPhoneField(context),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          CustomGlassButton(
                            semanticLabel: 'send_reset_request'.tr,
                            onPressed: _isSubmitting || _phone.isEmpty
                                ? null
                                : _submit,
                            minHeight: 52,
                            borderRadius: 18,
                            glassColor: IosSemanticColors.blue.withValues(
                              alpha: 0.88,
                            ),
                            foregroundColor: Colors.white,
                            child: _isSubmitting
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'send_reset_request'.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
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
    final scheme = theme.colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.75),
      ),
    );

    return TextField(
      controller: _phoneController,
      autofocus: true,
      enabled: !_isSubmitting,
      maxLength: _maxPhoneLength,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
        LengthLimitingTextInputFormatter(_maxPhoneLength),
      ],
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: 'phone_number_hint'.tr,
        errorText: _errorText,
        counterText: '',
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        prefixIcon: const Icon(
          CupertinoIcons.phone,
          color: IosSemanticColors.green,
        ),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(
            color: IosSemanticColors.blue,
            width: 1.5,
          ),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: IosSemanticColors.red),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(
            color: IosSemanticColors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
