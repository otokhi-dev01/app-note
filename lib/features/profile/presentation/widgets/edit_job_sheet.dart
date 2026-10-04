import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/profile/presentation/views/profile_edit_screen.dart';
import 'package:Note/shared/widgets/glass_input_surface.dart';

/// A focused, compact profile job editor styled like [EditNameSheet].
class EditJobSheet extends StatefulWidget {
  final String initialJob;
  final Future<bool> Function(String job) onSave;

  const EditJobSheet({
    super.key,
    required this.initialJob,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialJob,
    required Future<bool> Function(String job) onSave,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(
          title: 'edit_job_title'.tr,
          child: EditJobSheet(initialJob: initialJob, onSave: onSave),
        ),
      ),
    );
  }

  @override
  State<EditJobSheet> createState() => _EditJobSheetState();
}

class _EditJobSheetState extends State<EditJobSheet> {
  static const _maxJobLength = 80;

  late final TextEditingController _jobController;
  bool _isSaving = false;
  bool _showRequiredError = false;

  String get _trimmedJob => _jobController.text.trim();
  bool get _hasChanged => _trimmedJob != widget.initialJob.trim();
  bool get _canSave => !_isSaving && _trimmedJob.isNotEmpty && _hasChanged;

  @override
  void initState() {
    super.initState();
    _jobController = TextEditingController(text: widget.initialJob)
      ..addListener(_handleJobChanged);
    _jobController.selection = TextSelection.collapsed(
      offset: _jobController.text.length,
    );
  }

  @override
  void dispose() {
    _jobController
      ..removeListener(_handleJobChanged)
      ..dispose();
    super.dispose();
  }

  void _handleJobChanged() {
    if (!mounted) return;
    setState(() {
      if (_trimmedJob.isNotEmpty) _showRequiredError = false;
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_trimmedJob.isEmpty) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _showRequiredError = true);
      return;
    }
    if (!_hasChanged) return;

    unawaited(HapticFeedback.lightImpact());
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final saved = await widget.onSave(_trimmedJob);
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
              'job_label'.tr,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildJobField(theme, scheme),
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
                color: IosSemanticColors.indigo.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.briefcase_fill,
                size: 20,
                color: IosSemanticColors.indigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'edit_job_title'.tr,
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
          'edit_job_subtitle'.tr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildJobField(ThemeData theme, ColorScheme scheme) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.75),
      ),
    );

    return GlassInputSurface(
      child: TextField(
        controller: _jobController,
        autofocus: true,
        enabled: !_isSaving,
        maxLength: _maxJobLength,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        inputFormatters: [LengthLimitingTextInputFormatter(_maxJobLength)],
        style: theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: IosSemanticColors.blue,
        onSubmitted: (_) => _submit(),
        decoration: glassInputDecoration(
          InputDecoration(
            hintText: 'edit_job_hint'.tr,
            errorText: _showRequiredError ? 'job_required_message'.tr : null,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            suffixIcon: _jobController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'clear_action'.tr,
                    onPressed: _isSaving ? null : _jobController.clear,
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
