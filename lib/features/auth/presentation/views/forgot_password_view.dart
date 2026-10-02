import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Note/features/auth/presentation/controllers/account_input_controller.dart';
import 'package:Note/features/auth/presentation/controllers/google_password_verification_controller.dart';
import 'package:Note/features/auth/presentation/widgets/account_input_field.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/entities/security_question.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/auth/presentation/widgets/security_answers_form.dart';
import 'package:Note/features/auth/presentation/widgets/password_otp_step.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_toggle_button.dart';
import 'package:Note/shared/widgets/app_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});
  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

enum _RecoveryStep { account, code, security, password, complete }

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final AccountInputController _accountController;
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  _RecoveryStep _step = _RecoveryStep.account;
  bool _isSubmitting = false;
  String? _errorText;
  String? _resetToken;
  String? _notice;
  List<SecurityQuestion> _questions = [];
  List<SecurityAnswer> _answers = [];
  Timer? _resendTimer;
  int _resendSeconds = 0;
  String get _account => _accountController.account;

  @override
  void initState() {
    super.initState();
    _accountController = AccountInputController();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _resetToken = null;
    _answers = [];
    _accountController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendSeconds--);
      if (_resendSeconds == 0) timer.cancel();
    });
  }

  Future<void> _verifyWithGoogle() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _notice = null;
    });
    try {
      final result = await Get.find<GooglePasswordVerificationController>()
          .verify();
      if (!mounted) return;
      switch (result) {
        case Ok(:final value):
          _resetToken = value;
          _otpController.clear();
          _resendTimer?.cancel();
          _answers = [];
          _step = _RecoveryStep.password;
        case Err(:final failure):
          _errorText = failure.message;
        case null:
          break;
      }
    } catch (_) {
      if (mounted) _errorText = 'google_verification_failed'.tr;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _useSecurityQuestions() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (_account.isEmpty) {
      setState(() => _errorText = 'recovery_account_required'.tr);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _notice = null;
    });
    try {
      final result = await Get.find<GetSecurityQuestions>()(const NoParams());
      if (!mounted) return;
      switch (result) {
        case Ok(:final value):
          _questions = value;
          _answers = [];
          _otpController.clear();
          _resendTimer?.cancel();
          _step = _RecoveryStep.security;
        case Err(:final failure):
          _errorText = failure.message;
      }
    } catch (_) {
      if (mounted) _errorText = 'recovery_unexpected_error'.tr;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submit({bool resend = false}) async {
    if (_isSubmitting || (resend && _resendSeconds > 0)) return;
    if (_step == _RecoveryStep.complete) {
      unawaited(Get.offAllNamed(Routes.LOGIN));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _notice = null;
    });
    try {
      if (_step == _RecoveryStep.account || resend) {
        final result = await Get.find<ForgotPassword>()(_account);
        if (!mounted) return;
        switch (result) {
          case Ok():
            _step = _RecoveryStep.code;
            _otpController.clear();
            _notice = 'recovery_code_sent'.tr;
            _startResendCooldown();
          case Err(:final failure):
            _errorText = failure.message;
        }
      } else if (_step == _RecoveryStep.code) {
        final result = await Get.find<VerifyPasswordOtp>()(
          VerifyPasswordOtpParams(account: _account, otp: _otpController.text),
        );
        if (!mounted) return;
        switch (result) {
          case Ok(:final value):
            _resetToken = value;
            _otpController.clear();
            _resendTimer?.cancel();
            _step = _RecoveryStep.password;
          case Err(:final failure):
            _errorText = failure.message;
        }
      } else if (_step == _RecoveryStep.security) {
        final result = await Get.find<VerifySecurityAnswers>()(
          VerifySecurityAnswersParams(account: _account, answers: _answers),
        );
        if (!mounted) return;
        switch (result) {
          case Ok(:final value):
            _resetToken = value;
            _answers = [];
            _step = _RecoveryStep.password;
          case Err(:final failure):
            _errorText = failure.message;
        }
      } else {
        final result = await Get.find<ResetPassword>()(
          ResetPasswordParams(
            resetToken: _resetToken ?? '',
            newPassword: _passwordController.text,
            confirmPassword: _confirmController.text,
          ),
        );
        if (!mounted) return;
        switch (result) {
          case Ok():
            _resetToken = null;
            _passwordController.clear();
            _confirmController.clear();
            _step = _RecoveryStep.complete;
          case Err(:final failure):
            _errorText = failure.message;
        }
      }
    } catch (_) {
      if (mounted) _errorText = 'recovery_unexpected_error'.tr;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _startOver() {
    _resendTimer?.cancel();
    setState(() {
      _resetToken = null;
      _answers = [];
      _questions = [];
      _otpController.clear();
      _passwordController.clear();
      _confirmController.clear();
      _errorText = null;
      _notice = null;
      _resendSeconds = 0;
      _step = _RecoveryStep.account;
    });
  }

  String get _buttonLabel => switch (_step) {
    _RecoveryStep.account => 'send_reset_request'.tr,
    _RecoveryStep.code => 'recovery_verify_code'.tr,
    _RecoveryStep.security => 'recovery_verify_answers'.tr,
    _RecoveryStep.password => 'recovery_reset_password'.tr,
    _RecoveryStep.complete => 'sign_in_button'.tr,
  };

  void _back() {
    if (_step == _RecoveryStep.code) {
      _startOver();
    } else if (_step == _RecoveryStep.complete) {
      unawaited(Get.offAllNamed(Routes.LOGIN));
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_step == _RecoveryStep.code) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !_isSubmitting) _back();
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: isDark
                ? theme.scaffoldBackgroundColor
                : theme.colorScheme.surface,
            body: PasswordOtpStep(
              account: _account,
              controller: _otpController,
              resendSeconds: _resendSeconds,
              isSubmitting: _isSubmitting,
              errorText: _errorText,
              onVerify: () => _submit(),
              onResend: () => _submit(resend: true),
              onBack: _back,
              onCodeChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: !_isSubmitting && _step != _RecoveryStep.complete,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSubmitting && _step == _RecoveryStep.complete) {
          _back();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              _buildBackdrop(context),
              CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  AppScreenSliverAppBar(
                    backgroundColor: Colors.transparent,
                    shadow: const [],
                    // title: 'forgot_password_title'.tr,
                    centerTitle: true,
                    actions: const [LanguageToggleButton()],
                    leading: CustomGlassButton(
                      semanticLabel: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: _isSubmitting ? null : _back,
                      width: 44,
                      height: 44,
                      shape: GlassShape.circle,
                      blur: 10,
                      opacity: 0.15,
                      thickness: 8,
                      glassColor: null,
                      foregroundColor: theme.colorScheme.onSurface,
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.back, size: 23),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            18,
                            24,
                            MediaQuery.viewInsetsOf(context).bottom + 40,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: AppLogo(height: 78)
                                    .animate()
                                    .scale(
                                      duration: 600.ms,
                                      curve: Curves.easeOutBack,
                                      begin: const Offset(0.9, 0.9),
                                      end: const Offset(1, 1),
                                    )
                                    .fadeIn(duration: 400.ms),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: Text(
                                  "forgot_password_title".tr,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30,
                                        color: theme.colorScheme.primary,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              CustomGlassContainer(
                                borderRadius: 30,
                                blur: 35,
                                opacity: 0.1,
                                thickness: 15,
                                showGlow: true,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      // child: Container(
                                      //   width: 40,
                                      //   height: 4,
                                      //   margin: const EdgeInsets.only(
                                      //     bottom: 24,
                                      //   ),
                                      //   decoration: BoxDecoration(
                                      //     color: theme.dividerColor.withValues(
                                      //       alpha: 0.3,
                                      //     ),
                                      //     borderRadius: BorderRadius.circular(
                                      //       2,
                                      //     ),
                                      //   ),
                                      // ),
                                    ),
                                    ..._buildFields(context),
                                    if (_notice != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Text(
                                          _notice!,
                                          semanticsLabel: _notice,
                                        ),
                                      ),
                                    if (_errorText != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Semantics(
                                          liveRegion: true,
                                          child: Text(
                                            _errorText!,
                                            style: TextStyle(
                                              color: theme.colorScheme.error,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_step != _RecoveryStep.account) ...[
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => _submit(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _buttonLabel,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (_step == _RecoveryStep.account) ...[
                                Text(
                                  'google_verification_description'.tr,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                CustomGlassButton(
                                  semanticLabel: 'verify_with_google'.tr,
                                  onPressed: _isSubmitting
                                      ? null
                                      : _verifyWithGoogle,
                                  minHeight: 56,
                                  borderRadius: 26,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const FaIcon(
                                        FontAwesomeIcons.google,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text('verify_with_google'.tr),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_step == _RecoveryStep.security ||
                                  _step == _RecoveryStep.password)
                                TextButton(
                                  onPressed: _isSubmitting ? null : _startOver,
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                  ),
                                  child: Text('recovery_start_over'.tr),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackdrop(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -100,
            child: _glow(accent, 320, isDark ? 0.30 : 0.20),
          ),
          Positioned(
            bottom: -150,
            left: -120,
            child: _glow(accent, 340, isDark ? 0.22 : 0.14),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields(BuildContext context) {
    final theme = Theme.of(context);
    return switch (_step) {
      _RecoveryStep.account => [
        AccountInputField(
          controller: _accountController,
          enabled: !_isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_errorText != null) setState(() => _errorText = null);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: _isSubmitting ? null : _useSecurityQuestions,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              child: Text(
                'recovery_use_security_questions'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _buttonLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
      _RecoveryStep.code => [
        OtpCodeField(
          controller: _otpController,
          enabled: !_isSubmitting,
          hasError: _errorText != null,
          onSubmitted: () => _submit(),
        ),
      ],
      _RecoveryStep.security => [
        SecurityAnswersForm(
          questions: _questions,
          enabled: !_isSubmitting,
          onChanged: (answers) {
            _answers = answers;
            if (_errorText != null) setState(() => _errorText = null);
          },
        ),
      ],
      _RecoveryStep.password => [
        _field(
          context,
          controller: _passwordController,
          label: 'recovery_new_password'.tr,
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
          action: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _field(
          context,
          controller: _confirmController,
          label: 'confirm_password_hint'.tr,
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
        ),
      ],
      _RecoveryStep.complete => [
        const Center(child: Icon(Icons.check_circle_outline, size: 48)),
      ],
    };
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    List<String>? autofillHints,
    TextInputAction action = TextInputAction.done,
  }) {
    final theme = Theme.of(context);
    return CustomGlassTextField(
      key: ValueKey(label),
      controller: controller,
      enabled: !_isSubmitting,
      obscureText: obscure,
      textInputAction: action,
      onSubmitted: (_) {
        if (action == TextInputAction.next) {
          FocusScope.of(context).nextFocus();
        } else {
          _submit();
        }
      },
      onChanged: (_) {
        if (_errorText != null) setState(() => _errorText = null);
      },
      placeholder: label,
      prefixIcon: Icon(
        obscure ? CupertinoIcons.lock_fill : CupertinoIcons.person_fill,
        size: 20,
        color: theme.colorScheme.primary.withValues(alpha: 0.8),
      ),
      textStyle: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      placeholderStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      borderRadius: 18,
      height: 56,
    );
  }
}
