import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/profile/domain/entities/passport_card.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/features/profile/presentation/views/profile_edit_screen.dart';

typedef SavePassportInformation = Future<void> Function(PassportCard passport);

class EditPassportInformationSheet extends StatefulWidget {
  final PassportCard? initialCard;
  final SavePassportInformation onSave;

  const EditPassportInformationSheet({
    super.key,
    this.initialCard,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    PassportCard? initialCard,
    required SavePassportInformation onSave,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(
          title: 'edit_passport_information_title'.tr,
          child: EditPassportInformationSheet(
            initialCard: initialCard,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  @override
  State<EditPassportInformationSheet> createState() => _EditPassportInformationSheetState();
}

class _EditPassportInformationSheetState extends State<EditPassportInformationSheet> {
  static const _maxPassportLength = 40;
  static const _maxNameLength = 80;
  static const _maxNationalityLength = 60;
  static const _maxCountryLength = 60;

  late final TextEditingController _numberController;
  late final TextEditingController _nameController;
  late final TextEditingController _genderController;
  late final TextEditingController _nationalityController;
  late final TextEditingController _issuingCountryController;
  
  late final FocusNode _nameFocusNode;
  late final FocusNode _genderFocusNode;
  late final FocusNode _nationalityFocusNode;
  late final FocusNode _issuingCountryFocusNode;

  DateTime? _dateOfBirth;
  DateTime? _expiryDate;
  DateTime? _issuedDate;
  bool _isSaving = false;
  bool _showErrors = false;

  String get _passportNumber => _numberController.text.trim();
  String get _fullName => _nameController.text.trim();
  String get _gender => _genderController.text.trim();
  String get _nationality => _nationalityController.text.trim();
  String get _issuingCountry => _issuingCountryController.text.trim();

  bool get _isValid =>
      _passportNumber.isNotEmpty && _fullName.isNotEmpty && _dateOfBirth != null && _expiryDate != null;

  bool get _hasChanged {
    final initial = widget.initialCard;
    if (initial == null) return true;

    return _passportNumber != initial.passportNumber ||
           _fullName != initial.fullName ||
           _gender != initial.gender ||
           _nationality != initial.nationality ||
           _issuingCountry != initial.issuingCountry ||
           !_sameDay(_dateOfBirth, initial.dateOfBirthAsDate) ||
           !_sameDay(_expiryDate, initial.expiryDateAsDate) ||
           !_sameDay(_issuedDate, initial.issuedDateAsDate);
  }

  bool get _canSave => !_isSaving && _isValid && _hasChanged;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCard;
    _numberController = TextEditingController(text: initial?.passportNumber ?? '')..addListener(_handleChanged);
    _nameController = TextEditingController(text: initial?.fullName ?? '')..addListener(_handleChanged);
    _genderController = TextEditingController(text: initial?.gender ?? '')..addListener(_handleChanged);
    _nationalityController = TextEditingController(text: initial?.nationality ?? '')..addListener(_handleChanged);
    _issuingCountryController = TextEditingController(text: initial?.issuingCountry ?? '')..addListener(_handleChanged);

    _nameFocusNode = FocusNode();
    _genderFocusNode = FocusNode();
    _nationalityFocusNode = FocusNode();
    _issuingCountryFocusNode = FocusNode();

    _dateOfBirth = initial?.dateOfBirthAsDate;
    _expiryDate = initial?.expiryDateAsDate;
    _issuedDate = initial?.issuedDateAsDate;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _genderController.dispose();
    _nationalityController.dispose();
    _issuingCountryController.dispose();
    _nameFocusNode.dispose();
    _genderFocusNode.dispose();
    _nationalityFocusNode.dispose();
    _issuingCountryFocusNode.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickDate(String type) async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    
    DateTime initial;
    DateTime first;
    DateTime last;

    if (type == 'dob') {
      initial = _dateOfBirth ?? DateTime(now.year - 30, now.month, now.day);
      first = DateTime(1900);
      last = now;
    } else if (type == 'expiry') {
      initial = _expiryDate ?? DateTime(now.year + 5, now.month, now.day);
      first = now;
      last = DateTime(now.year + 50);
    } else {
      // issued
      initial = _issuedDate ?? DateTime(now.year - 5, now.month, now.day);
      first = DateTime(1900);
      last = now;
    }

    final picked = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) => ProfileDatePickerScreen(
          initialDate: initial,
          firstDate: first,
          lastDate: last,
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        if (type == 'dob') {
          _dateOfBirth = picked;
        } else if (type == 'expiry') {
          _expiryDate = picked;
        } else {
          _issuedDate = picked;
        }
      });
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

    final passport = PassportCard(
      passportNumber: _passportNumber,
      fullName: _fullName,
      dateOfBirth: _formatDate(_dateOfBirth!),
      gender: _gender,
      nationality: _nationality,
      expiryDate: _formatDate(_expiryDate!),
      issuedDate: _issuedDate != null ? _formatDate(_issuedDate!) : '',
      issuingCountry: _issuingCountry,
      mrzLines: widget.initialCard?.mrzLines ?? const [],
      imagePath: widget.initialCard?.imagePath,
    );

    await widget.onSave(passport);
    
    if (!mounted) return;
    Navigator.of(context).pop();
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
              'edit_passport_information_title'.tr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'edit_id_information_subtitle'.tr, // Reuse subtitle
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            _label(theme, scheme, 'passport_number_label'.tr),
            const SizedBox(height: 8),
            _textField(
              theme,
              scheme,
              controller: _numberController,
              hint: 'passport_number_hint'.tr,
              maxLength: _maxPassportLength,
              autofocus: true,
              action: TextInputAction.next,
              errorText: _showErrors && _passportNumber.isEmpty ? 'field_required'.tr : null,
              onSubmitted: (_) => _nameFocusNode.requestFocus(),
            ),
            const SizedBox(height: 14),
            _label(theme, scheme, 'full_name_label'.tr),
            const SizedBox(height: 8),
            _textField(
              theme,
              scheme,
              controller: _nameController,
              focusNode: _nameFocusNode,
              hint: 'full_name_hint'.tr,
              maxLength: _maxNameLength,
              textCapitalization: TextCapitalization.words,
              action: TextInputAction.next,
              errorText: _showErrors && _fullName.isEmpty ? 'field_required'.tr : null,
              onSubmitted: (_) => _genderFocusNode.requestFocus(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(theme, scheme, 'gender_label'.tr),
                      const SizedBox(height: 8),
                      _textField(
                        theme,
                        scheme,
                        controller: _genderController,
                        focusNode: _genderFocusNode,
                        hint: 'gender_label'.tr,
                        maxLength: 10,
                        action: TextInputAction.next,
                        onSubmitted: (_) => _nationalityFocusNode.requestFocus(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(theme, scheme, 'nationality_label'.tr),
                      const SizedBox(height: 8),
                      _textField(
                        theme,
                        scheme,
                        controller: _nationalityController,
                        focusNode: _nationalityFocusNode,
                        hint: 'nationality_label'.tr,
                        maxLength: _maxNationalityLength,
                        action: TextInputAction.next,
                        onSubmitted: (_) => _issuingCountryFocusNode.requestFocus(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _label(theme, scheme, 'date_of_birth_label'.tr),
            const SizedBox(height: 8),
            _datePickerField(theme, scheme, _dateOfBirth, 'dob', 'select_dob_hint'.tr),
            const SizedBox(height: 14),
            _label(theme, scheme, 'expiry_date_label'.tr),
            const SizedBox(height: 8),
            _datePickerField(theme, scheme, _expiryDate, 'expiry', 'select_expiry_hint'.tr),
            const SizedBox(height: 14),
            _label(theme, scheme, 'issuing_country_label'.tr),
            const SizedBox(height: 8),
            _textField(
              theme,
              scheme,
              controller: _issuingCountryController,
              focusNode: _issuingCountryFocusNode,
              hint: 'issuing_country_hint'.tr,
              maxLength: _maxCountryLength,
              action: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
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
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: !_isSaving,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      textInputAction: action,
      onSubmitted: onSubmitted,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        counterText: '',
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: _border(scheme),
        enabledBorder: _border(scheme),
        focusedBorder: _border(scheme).copyWith(
          borderSide: const BorderSide(color: IosSemanticColors.blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _datePickerField(ThemeData theme, ColorScheme scheme, DateTime? date, String type, String hint) {
    final missing = _showErrors && date == null && (type == 'dob' || type == 'expiry');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isSaving ? null : () => _pickDate(type),
      child: InputDecorator(
        decoration: InputDecoration(
          errorText: missing ? 'field_required'.tr : null,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: _border(scheme).copyWith(
            borderSide: missing ? const BorderSide(color: IosSemanticColors.red) : null,
          ),
          enabledBorder: _border(scheme),
          suffixIcon: const Icon(CupertinoIcons.calendar, size: 20, color: IosSemanticColors.pink),
        ),
        child: Text(
          date == null ? hint : _formatDate(date),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: date == null ? scheme.onSurfaceVariant : scheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(ColorScheme scheme) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.75)),
  );

  Widget _actions(ColorScheme scheme) => Row(
    children: [
      if (widget.initialCard != null)
        IconButton(
          onPressed: _isSaving ? null : () async {
            unawaited(HapticFeedback.heavyImpact());
            final confirm = await showCupertinoDialog<bool>(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: Text('passport_information_deleted'.tr),
                content: const Text('Are you sure you want to delete this passport?'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('cancel_action'.tr),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('daily_delete'.tr),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await Get.find<ProfileController>().deletePassportInformation(widget.initialCard!.passportNumber);
              if (mounted) Navigator.pop(context);
            }
          },
          icon: const Icon(CupertinoIcons.trash, color: IosSemanticColors.red),
        ),
      const Spacer(),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSaving
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text('save_action'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
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
    return first.year == second.year && first.month == second.month && first.day == second.day;
  }
}
