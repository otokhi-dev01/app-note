import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/profile/presentation/widgets/profile_glass_popup.dart';

class EditIdInformationSheet extends StatefulWidget {
  final String initialIdNumber;
  final String initialName;
  final DateTime? initialDateOfBirth;
  final Future<bool> Function(
    String idNumber,
    String name,
    DateTime dateOfBirth,
  )
  onSave;

  const EditIdInformationSheet({
    super.key,
    required this.initialIdNumber,
    required this.initialName,
    required this.initialDateOfBirth,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialIdNumber,
    required String initialName,
    required DateTime? initialDateOfBirth,
    required Future<bool> Function(
      String idNumber,
      String name,
      DateTime dateOfBirth,
    )
    onSave,
  }) {
    return ProfileGlassPopup.show<void>(
      context: context,
      maxWidth: 420,
      barrierDismissible: false,
      builder: (context) => EditIdInformationSheet(
        initialIdNumber: initialIdNumber,
        initialName: initialName,
        initialDateOfBirth: initialDateOfBirth,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditIdInformationSheet> createState() => _EditIdInformationSheetState();
}

class _EditIdInformationSheetState extends State<EditIdInformationSheet> {
  static const _maxIdLength = 40;
  static const _maxNameLength = 80;

  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  DateTime? _dateOfBirth;
  bool _isSaving = false;
  bool _showErrors = false;

  String get _idNumber => _idController.text.trim();
  String get _name => _nameController.text.trim();
  bool get _isValid =>
      _idNumber.isNotEmpty && _name.isNotEmpty && _dateOfBirth != null;
  bool get _hasChanged =>
      _idNumber != widget.initialIdNumber.trim() ||
      _name != widget.initialName.trim() ||
      !_sameDay(_dateOfBirth, widget.initialDateOfBirth);
  bool get _canSave => !_isSaving && _isValid && _hasChanged;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initialIdNumber)
      ..addListener(_handleChanged);
    _nameController = TextEditingController(text: widget.initialName)
      ..addListener(_handleChanged);
    _nameFocusNode = FocusNode();
    _dateOfBirth = widget.initialDateOfBirth;
  }

  @override
  void dispose() {
    _idController
      ..removeListener(_handleChanged)
      ..dispose();
    _nameController
      ..removeListener(_handleChanged)
      ..dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'date_of_birth_label'.tr,
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_isValid) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _showErrors = true);
      return;
    }
    if (!_hasChanged) return;

    unawaited(HapticFeedback.lightImpact());
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final saved = await widget.onSave(_idNumber, _name, _dateOfBirth!);
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
            Text(
              'edit_id_information_title'.tr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'edit_id_information_subtitle'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            _label(theme, scheme, 'id_number_label'.tr),
            const SizedBox(height: 8),
            _textField(
              theme,
              scheme,
              controller: _idController,
              hint: 'id_number_hint'.tr,
              maxLength: _maxIdLength,
              autofocus: true,
              keyboardType: TextInputType.text,
              action: TextInputAction.next,
              errorText: _showErrors && _idNumber.isEmpty
                  ? 'id_number_required'.tr
                  : null,
              onSubmitted: (_) => _nameFocusNode.requestFocus(),
            ),
            const SizedBox(height: 14),
            _label(theme, scheme, 'id_name_label'.tr),
            const SizedBox(height: 8),
            _textField(
              theme,
              scheme,
              controller: _nameController,
              focusNode: _nameFocusNode,
              hint: 'id_name_hint'.tr,
              maxLength: _maxNameLength,
              textCapitalization: TextCapitalization.words,
              action: TextInputAction.done,
              errorText: _showErrors && _name.isEmpty
                  ? 'id_name_required'.tr
                  : null,
              onSubmitted: (_) => _pickDate(),
            ),
            const SizedBox(height: 14),
            _label(theme, scheme, 'date_of_birth_label'.tr),
            const SizedBox(height: 8),
            _dateField(theme, scheme),
            const SizedBox(height: 22),
            _actions(scheme),
          ],
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, ColorScheme scheme, String text) => Text(
    text,
    style: theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _textField(
    ThemeData theme,
    ColorScheme scheme, {
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    required TextInputAction action,
    required ValueChanged<String> onSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? errorText,
  }) {
    final border = _border(scheme);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: !_isSaving,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: action,
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
      onSubmitted: onSubmitted,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        counterText: '',
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
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

  Widget _dateField(ThemeData theme, ColorScheme scheme) {
    final missing = _showErrors && _dateOfBirth == null;
    final border = _border(scheme).copyWith(
      borderSide: missing
          ? const BorderSide(color: IosSemanticColors.red)
          : _border(scheme).borderSide,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isSaving ? null : _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          errorText: missing ? 'date_of_birth_required'.tr : null,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: border,
          enabledBorder: border,
          suffixIcon: Icon(
            CupertinoIcons.calendar,
            size: 20,
            color: IosSemanticColors.pink,
          ),
        ),
        child: Text(
          _dateOfBirth == null
              ? 'date_of_birth_hint'.tr
              : _formatDate(_dateOfBirth!),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _dateOfBirth == null
                ? scheme.onSurfaceVariant
                : scheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(ColorScheme scheme) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: scheme.outlineVariant.withValues(alpha: 0.75),
    ),
  );

  Widget _actions(ColorScheme scheme) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        child: Text('cancel_action'.tr),
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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool _sameDay(DateTime? first, DateTime? second) {
    if (first == null || second == null) return first == second;
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
