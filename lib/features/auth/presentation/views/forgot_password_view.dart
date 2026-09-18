import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/entities/security_question.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/auth/presentation/widgets/security_answers_form.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/app_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});
  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

enum _RecoveryStep { account, code, security, password, complete }

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final TextEditingController _accountController;
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
  String get _account => _accountController.text.trim();

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    final values = arguments is Map ? arguments : {};
    _accountController = TextEditingController(
      text: values['initialAccount']?.toString() ?? '',
    );
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

  String get _description => switch (_step) {
    _RecoveryStep.account => 'forgot_password_desc'.tr,
    _RecoveryStep.code => 'recovery_code_desc'.trParams({'account': _account}),
    _RecoveryStep.security => 'recovery_security_desc'.trParams({
      'account': _account,
    }),
    _RecoveryStep.password => 'recovery_password_desc'.tr,
    _RecoveryStep.complete => 'recovery_complete_desc'.tr,
  };

  String get _buttonLabel => switch (_step) {
    _RecoveryStep.account => 'send_reset_request'.tr,
    _RecoveryStep.code => 'recovery_verify_code'.tr,
    _RecoveryStep.security => 'recovery_verify_answers'.tr,
    _RecoveryStep.password => 'recovery_reset_password'.tr,
    _RecoveryStep.complete => 'sign_in_button'.tr,
  };

  void _back() {
    if (_step == _RecoveryStep.complete) {
      unawaited(Get.offAllNamed(Routes.LOGIN));
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
          body: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: BouncingScrollPhysics(),
            slivers: [
              AppScreenSliverAppBar(
                title: 'forgot_password_title'.tr,
                centerTitle: true,
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
                  child: Icon(CupertinoIcons.back, size: 23),
                ),
              ),
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 620),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
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
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.45,
                              fontSize: 16,
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
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 24),
                                    decoration: BoxDecoration(
                                      color: theme.dividerColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : () => _submit(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
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
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
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
                          if (_step == _RecoveryStep.account ||
                              _step == _RecoveryStep.code)
                            TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : _useSecurityQuestions,
                              child: Text('recovery_use_security_questions'.tr),
                            ),
                          if (_step == _RecoveryStep.code)
                            TextButton(
                              onPressed: _isSubmitting || _resendSeconds > 0
                                  ? null
                                  : () => _submit(resend: true),
                              child: Text(
                                _resendSeconds > 0
                                    ? 'recovery_resend_countdown'.trParams({
                                        'seconds': '$_resendSeconds',
                                      })
                                    : 'recovery_resend_code'.tr,
                              ),
                            ),
                          if (_step == _RecoveryStep.code ||
                              _step == _RecoveryStep.security ||
                              _step == _RecoveryStep.password)
                            TextButton(
                              onPressed: _isSubmitting ? null : _startOver,
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
        ),
      ),
    );
  }

  List<Widget> _buildFields(BuildContext context) => switch (_step) {
    _RecoveryStep.account => [
      _field(
        context,
        controller: _accountController,
        label: 'username_email_phone_hint'.tr,
        autofillHints: const [AutofillHints.username],
      ),
    ],
    _RecoveryStep.code => [
      _field(
        context,
        controller: _otpController,
        label: 'recovery_code_label'.tr,
        autofillHints: const [AutofillHints.oneTimeCode],
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

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    List<String>? autofillHints,
    TextInputAction action = TextInputAction.done,
  }) {
    final theme = Theme.of(context);
    return TextField(
      key: ValueKey(label),
      controller: controller,
      enabled: !_isSubmitting,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: autofillHints,
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
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(obscure ? Icons.lock_outline : Icons.person_outline),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
