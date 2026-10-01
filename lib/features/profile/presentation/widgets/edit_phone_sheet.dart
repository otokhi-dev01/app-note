import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/profile/presentation/views/profile_edit_screen.dart';

/// A focused, compact profile phone number editor styled like [EditNameSheet].
class EditPhoneSheet extends StatefulWidget {
  final String initialPhone;
  final Future<bool> Function(String phone) onSave;

  const EditPhoneSheet({
    super.key,
    required this.initialPhone,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialPhone,
    required Future<bool> Function(String phone) onSave,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(
          title: 'edit_phone_title'.tr,
          child: EditPhoneSheet(initialPhone: initialPhone, onSave: onSave),
        ),
      ),
    );
  }

  @override
  State<EditPhoneSheet> createState() => _EditPhoneSheetState();
}

class _EditPhoneSheetState extends State<EditPhoneSheet> {
  static const _maxPhoneLength = 30;

  late final TextEditingController _phoneController;
  bool _isSaving = false;
  bool _showRequiredError = false;

  String get _trimmedPhone => _phoneController.text.trim();
  bool get _hasChanged => _trimmedPhone != widget.initialPhone.trim();
  bool get _canSave => !_isSaving && _trimmedPhone.isNotEmpty && _hasChanged;

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
    setState(() {
      if (_trimmedPhone.isNotEmpty) _showRequiredError = false;
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_trimmedPhone.isEmpty) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _showRequiredError = true);
      return;
    }
    if (!_hasChanged) return;

    unawaited(HapticFeedback.lightImpact());
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final saved = await widget.onSave(_trimmedPhone);
    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: !_isSaving,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, scheme),
            const SizedBox(height: 20),
            Text(
              'phone_label'.tr,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildPhoneField(theme, scheme),
            const SizedBox(height: 20),
            _buildActions(context, scheme),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: IosSemanticColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.phone_fill,
                size: 20,
                color: IosSemanticColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'edit_phone_title'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'edit_phone_subtitle'.tr,
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
      enabled: !_isSaving,
      maxLength: _maxPhoneLength,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        LengthLimitingTextInputFormatter(_maxPhoneLength),
        FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\s\(\)]')),
      ],
      style: theme.textTheme.bodyLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: IosSemanticColors.blue,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: 'edit_phone_hint'.tr,
        errorText: _showRequiredError ? 'phone_required_message'.tr : null,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        suffixIcon: _phoneController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'clear_action'.tr,
                onPressed: _isSaving ? null : _phoneController.clear,
                icon: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 19,
                  color: IosSemanticColors.gray,
                ),
              ),
        counterStyle: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
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

  Widget _buildActions(BuildContext context, ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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
          onPressed: _canSave ? _submit : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(116, 48),
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
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'save_action'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}
