import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/theme/app_colors.dart';

class PasswordOtpStep extends StatelessWidget {
  const PasswordOtpStep({
    super.key,
    required this.account,
    required this.controller,
    required this.resendSeconds,
    required this.isSubmitting,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
    required this.onCodeChanged,
    this.errorText,
  });

  final String account;
  final TextEditingController controller;
  final int resendSeconds;
  final bool isSubmitting;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onBack;
  final ValueChanged<String> onCodeChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = AppColors.onAccent(colors.primary);
    final countdown =
        '${(resendSeconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(resendSeconds % 60).toString().padLeft(2, '0')}';

    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(30, 12, 30, 32),
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: isSubmitting ? null : onBack,
                color: colors.onSurface,
                icon: const Icon(CupertinoIcons.back, size: 28),
              ),
            ),
            const SizedBox(height: 52),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'recovery_otp_title'.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'recovery_otp_description'.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        height: 1.6,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      account,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 54),
                    OtpCodeField(
                      controller: controller,
                      enabled: !isSubmitting,
                      hasError: errorText != null,
                      onSubmitted: onVerify,
                      onChanged: onCodeChanged,
                    ),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            errorText!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 64),
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        final canVerify =
                            !isSubmitting && controller.text.length == 6;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: [
                                Color.lerp(
                                  colors.primary,
                                  colors.surface,
                                  .16,
                                )!,
                                Color.lerp(colors.primary, Colors.black, .12)!,
                              ],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: canVerify ? onVerify : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: foreground,
                              disabledForegroundColor: foreground.withValues(
                                alpha: .65,
                              ),
                              elevation: 0,
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: isSubmitting
                                ? SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      color: foreground,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'recovery_verify_code'.tr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    if (resendSeconds > 0)
                      Text(
                        'recovery_otp_countdown'.trParams({'time': countdown}),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'recovery_otp_not_received'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.of(context).secondaryText,
                          ),
                        ),
                        TextButton(
                          onPressed: isSubmitting || resendSeconds > 0
                              ? null
                              : onResend,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                            disabledForegroundColor: colors.primary.withValues(
                              alpha: .4,
                            ),
                          ),
                          child: Text('recovery_resend_code'.tr),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single native input keeps paste, deletion, and SMS autofill intact while
/// presenting the code in six separate cells.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.hasError,
    required this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool hasError;
  final VoidCallback onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _focusNode]),
      builder: (context, _) {
        final code = widget.controller.text;
        final cursor = widget.controller.selection.extentOffset;
        final activeCell = (cursor < 0 ? code.length : cursor).clamp(0, 5);
        return SizedBox(
          height: 52,
          child: Stack(
            children: [
              ExcludeSemantics(
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: List.generate(6, (index) {
                    final focused =
                        widget.enabled &&
                        _focusNode.hasFocus &&
                        index == activeCell;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: widget.hasError
                                ? colors.error
                                : focused
                                ? colors.primary
                                : theme.dividerColor.withValues(alpha: .65),
                            width: focused ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: theme.brightness == Brightness.dark
                                    ? .2
                                    : .10,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          index < code.length ? code[index] : '',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Positioned.fill(
                child: Semantics(
                  label: 'recovery_code_label'.tr,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    showCursor: false,
                    style: const TextStyle(color: Colors.transparent),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      if (value.length == 6) widget.onSubmitted();
                    },
                    onChanged: widget.onChanged,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
