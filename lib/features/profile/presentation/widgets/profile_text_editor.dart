import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/profile/presentation/widgets/profile_editor_controls.dart';

/// Shared editor for profile text fields, with explicit Save and Cancel.
class ProfileTextEditor extends StatefulWidget {
  final String title;
  final String subtitle;
  final String label;
  final String hint;
  final IconData icon;
  final String initialValue;
  final Future<bool> Function(String value) onSave;
  final int? maxLength;
  final String? requiredMessage;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const ProfileTextEditor({
    super.key,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.onSave,
    this.icon = CupertinoIcons.person_fill,
    this.maxLength,
    this.requiredMessage,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<ProfileTextEditor> createState() => _ProfileTextEditorState();
}

class _ProfileTextEditorState extends State<ProfileTextEditor> {
  late final TextEditingController _fieldController;
  bool _isSaving = false;
  bool _showRequiredError = false;

  String get _trimmedValue => _fieldController.text.trim();
  bool get _hasChanged => _trimmedValue != widget.initialValue.trim();
  bool get _canSave =>
      !_isSaving &&
      (widget.requiredMessage == null || _trimmedValue.isNotEmpty) &&
      _hasChanged;

  @override
  void initState() {
    super.initState();
    _fieldController = TextEditingController(text: widget.initialValue)
      ..addListener(_handleValueChanged);
    _fieldController.selection = TextSelection.collapsed(
      offset: _fieldController.text.length,
    );
  }

  @override
  void dispose() {
    _fieldController
      ..removeListener(_handleValueChanged)
      ..dispose();
    super.dispose();
  }

  void _handleValueChanged() {
    if (!mounted) return;
    setState(() {
      if (_trimmedValue.isNotEmpty) _showRequiredError = false;
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (widget.requiredMessage != null && _trimmedValue.isEmpty) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _showRequiredError = true);
      return;
    }
    if (!_hasChanged) return;

    unawaited(HapticFeedback.lightImpact());
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final saved = await widget.onSave(_trimmedValue);
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
            ProfileEditorHeader(
              title: widget.title,
              subtitle: widget.subtitle,
              icon: widget.icon,
            ),
            const SizedBox(height: 20),
            Text(
              widget.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildField(theme, scheme),
            const SizedBox(height: 20),
            ProfileEditorActions(
              isSaving: _isSaving,
              onSave: _canSave ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(ThemeData theme, ColorScheme scheme) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.75),
      ),
    );

    return TextField(
      controller: _fieldController,
      autofocus: true,
      enabled: !_isSaving,
      maxLength: widget.maxLength,
      textCapitalization: widget.textCapitalization,
      keyboardType: widget.keyboardType,
      autocorrect: widget.textCapitalization != TextCapitalization.none,
      textInputAction: TextInputAction.done,
      inputFormatters: [LengthLimitingTextInputFormatter(widget.maxLength)],
      style: theme.textTheme.bodyLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: IosSemanticColors.blue,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: widget.hint,
        errorText: _showRequiredError ? widget.requiredMessage : null,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        suffixIcon: _fieldController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'clear_action'.tr,
                onPressed: _isSaving ? null : _fieldController.clear,
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
}
