import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Two-field profile editor using the same dialog language as Edit Name.
class EditJobBioSheet extends StatefulWidget {
  final String initialJob;
  final String initialBio;
  final Future<bool> Function(String job, String bio) onSave;

  const EditJobBioSheet({
    super.key,
    required this.initialJob,
    required this.initialBio,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialJob,
    required String initialBio,
    required Future<bool> Function(String job, String bio) onSave,
  }) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, _) => EditJobBioSheet(
        initialJob: initialJob,
        initialBio: initialBio,
        onSave: onSave,
      ),
      transitionBuilder: (context, animation, _, child) {
        final entrance = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: entrance,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(entrance),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<EditJobBioSheet> createState() => _EditJobBioSheetState();
}

class _EditJobBioSheetState extends State<EditJobBioSheet> {
  static const _maxJobLength = 80;
  static const _maxBioLength = 240;

  late final TextEditingController _jobController;
  late final TextEditingController _bioController;
  late final FocusNode _bioFocusNode;
  bool _isSaving = false;

  String get _job => _jobController.text.trim();
  String get _bio => _bioController.text.trim();
  bool get _hasChanged =>
      _job != widget.initialJob.trim() || _bio != widget.initialBio.trim();
  bool get _canSave => !_isSaving && _hasChanged;

  @override
  void initState() {
    super.initState();
    _jobController = TextEditingController(text: widget.initialJob)
      ..addListener(_handleChanged);
    _bioController = TextEditingController(text: widget.initialBio)
      ..addListener(_handleChanged);
    _bioFocusNode = FocusNode();
    _jobController.selection = TextSelection.collapsed(
      offset: _jobController.text.length,
    );
  }

  @override
  void dispose() {
    _jobController
      ..removeListener(_handleChanged)
      ..dispose();
    _bioController
      ..removeListener(_handleChanged)
      ..dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_canSave) return;

    unawaited(HapticFeedback.lightImpact());
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final saved = await widget.onSave(_job, _bio);
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
      child: Dialog(
        elevation: 18,
        shadowColor: Colors.black.withValues(alpha: 0.24),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              22,
              24,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, theme, scheme),
                const SizedBox(height: 24),
                _buildLabel(theme, scheme, 'job_label'.tr),
                const SizedBox(height: 8),
                _buildField(
                  theme,
                  scheme,
                  controller: _jobController,
                  hint: 'edit_job_hint'.tr,
                  maxLength: _maxJobLength,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _bioFocusNode.requestFocus(),
                ),
                const SizedBox(height: 14),
                _buildLabel(theme, scheme, 'bio_label'.tr),
                const SizedBox(height: 8),
                _buildField(
                  theme,
                  scheme,
                  controller: _bioController,
                  focusNode: _bioFocusNode,
                  hint: 'edit_bio_hint'.tr,
                  maxLength: _maxBioLength,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 22),
                _buildActions(context, scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'edit_job_bio_title'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'edit_job_bio_subtitle'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          icon: const Icon(CupertinoIcons.xmark, size: 17),
          color: scheme.onSurfaceVariant,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(36),
            maximumSize: const Size.square(36),
            backgroundColor: scheme.surfaceContainerHighest,
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(ThemeData theme, ColorScheme scheme, String label) {
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildField(
    ThemeData theme,
    ColorScheme scheme, {
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    FocusNode? focusNode,
    bool autofocus = false,
    int minLines = 1,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.75),
      ),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: !_isSaving,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
      onSubmitted: onSubmitted,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: scheme.primary,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        counterStyle: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
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
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            disabledBackgroundColor: scheme.primary.withValues(alpha: 0.18),
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
                    color: scheme.onPrimary,
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
