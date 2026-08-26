import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/core/utils/validators.dart';
import 'package:Note/features/profile/presentation/widgets/profile_glass_popup.dart';

/// Shared forgot-password dialog used from both Login and Profile.
class ForgotPasswordPopup extends StatefulWidget {
  final String initialPhone;
  final Future<bool> Function(String phone) onSubmit;

  const ForgotPasswordPopup({
    super.key,
    required this.initialPhone,
    required this.onSubmit,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialPhone,
    required Future<bool> Function(String phone) onSubmit,
  }) {
    return ProfileGlassPopup.show<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ForgotPasswordPopup(initialPhone: initialPhone, onSubmit: onSubmit),
    );
  }

  @override
  State<ForgotPasswordPopup> createState() => _ForgotPasswordPopupState();
}

class _ForgotPasswordPopupState extends State<ForgotPasswordPopup> {
  static const _maxPhoneLength = 16;

  late final TextEditingController _phoneController;
  bool _isSubmitting = false;
  String? _errorText;

  String get _phone => _phoneController.text.trim();
  bool get _canSubmit => !_isSubmitting && _phone.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone)
      ..addListener(_handlePhoneChanged);
    _phoneController.selection = TextSelection.collapsed(
      offset: _phoneController.text.length,
    );
  }

  @override
  void dispose() {
    _phoneController
      ..removeListener(_handlePhoneChanged)
      ..dispose();
    super.dispose();
  }

  void _handlePhoneChanged() {
    if (!mounted) return;
    setState(() => _errorText = null);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final invalid = Validators.phone(_phone);
    if (invalid != null) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _errorText = invalid);
      return;
    }

    unawaited(HapticFeedback.lightImpact());
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final sent = await widget.onSubmit(_phone);
    if (!mounted) return;

    if (sent) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: !_isSubmitting,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, scheme),
            const SizedBox(height: 20),
            Text(
              'phone_number_label'.tr,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildPhoneField(theme, scheme),
            const SizedBox(height: 20),
            _buildActions(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: IosSemanticColors.orange,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.lock_rotation,
                size: 21,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'forgot_password_title'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'forgot_password_desc'.tr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(ThemeData theme, ColorScheme scheme) {
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
      style: theme.textTheme.bodyLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: IosSemanticColors.blue,
      decoration: InputDecoration(
        hintText: 'phone_number_hint'.tr,
        errorText: _errorText,
        counterText: '',
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        prefixIcon: Icon(
          CupertinoIcons.phone,
          size: 20,
          color: IosSemanticColors.green,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        errorStyle: theme.textTheme.labelSmall?.copyWith(
          color: IosSemanticColors.red,
          fontWeight: FontWeight.w500,
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

  Widget _buildActions(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            minimumSize: const Size(88, 48),
            foregroundColor: scheme.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'cancel_action'.tr,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(132, 48),
            backgroundColor: IosSemanticColors.blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: IosSemanticColors.blue.withValues(
              alpha: 0.18,
            ),
            disabledForegroundColor: scheme.onSurfaceVariant.withValues(
              alpha: 0.55,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isSubmitting
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'send_reset_request'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}
