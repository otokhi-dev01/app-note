import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/profile/presentation/widgets/profile_glass_popup.dart';

/// A focused, compact profile-name editor.
class EditNameSheet extends StatefulWidget {
  final String initialName;
  final Future<bool> Function(String name) onSave;

  const EditNameSheet({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialName,
    required Future<bool> Function(String name) onSave,
  }) {
    return ProfileGlassPopup.show<void>(
      context: context,
      builder: (context) =>
          EditNameSheet(initialName: initialName, onSave: onSave),
    );
  }

  @override
  State<EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<EditNameSheet> {
  static const _maxNameLength = 60;

  late final TextEditingController _nameController;
  bool _isSaving = false;
  bool _showRequiredError = false;

  String get _trimmedName => _nameController.text.trim();
  bool get _hasChanged => _trimmedName != widget.initialName.trim();
  bool get _canSave => !_isSaving && _trimmedName.isNotEmpty && _hasChanged;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName)
      ..addListener(_handleNameChanged);
    _nameController.selection = TextSelection.collapsed(
      offset: _nameController.text.length,
    );
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_handleNameChanged)
      ..dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (!mounted) return;
    setState(() {
      if (_trimmedName.isNotEmpty) _showRequiredError = false;
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_trimmedName.isEmpty) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _showRequiredError = true);
      return;
    }
    if (!_hasChanged) return;

    unawaited(HapticFeedback.lightImpact());
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final saved = await widget.onSave(_trimmedName);
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
              'full_name_label'.tr,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildNameField(theme, scheme),
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
        Text(
          'edit_name_title'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'edit_name_subtitle'.tr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(ThemeData theme, ColorScheme scheme) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.75),
      ),
    );

    return TextField(
      controller: _nameController,
      autofocus: true,
      enabled: !_isSaving,
      maxLength: _maxNameLength,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      inputFormatters: [LengthLimitingTextInputFormatter(_maxNameLength)],
      style: theme.textTheme.bodyLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: IosSemanticColors.blue,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: 'edit_name_hint'.tr,
        errorText: _showRequiredError ? 'name_required_message'.tr : null,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        suffixIcon: _nameController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'clear_action'.tr,
                onPressed: _isSaving ? null : _nameController.clear,
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
              ? SizedBox.square(
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
