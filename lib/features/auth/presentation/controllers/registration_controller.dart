import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/network/access_token.dart';
import 'package:Note/core/utils/validators.dart';
import 'package:Note/features/auth/data/services/registration_service.dart';
import 'package:Note/features/auth/presentation/controllers/account_input_controller.dart';
import 'package:Note/routes/app_pages.dart';

class RegistrationController extends GetxController
    with WidgetsBindingObserver {
  RegistrationController(this._service, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final RegistrationService _service;
  final DateTime Function() _now;
  final accountController = AccountInputController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpController = TextEditingController();
  final isLoading = false.obs;
  final retryIn = 0.obs;
  final resendIn = 0.obs;
  final isEmailStep = false.obs;
  final isOtpStep = false.obs;
  final accountCreated = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final error = ''.obs;
  final completed = false.obs;
  String? _completedAccount;
  bool _completedEmailVerified = false;
  bool _openingLogin = false;

  String? get completedAccount => _completedAccount;
  bool get completedEmailVerified => _completedEmailVerified;
  final verificationEmail = ''.obs;
  String _password = '';
  String _registrationAccount = '';
  bool _isEmailAccount = false;
  bool _isPhoneAccount = false;

  bool get canEditProfileAccount => true;
  bool _emailVerified = false;
  String _profileToken = '';
  String? _lastSentEmail;
  DateTime? _retryAt;
  DateTime? _resendAt;
  Timer? _timer;
  CancelToken? _cancelToken;

  void togglePasswordVisibility() => isPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshCountdowns();
  }

  String? validate() {
    final account = accountController.account;
    if (account.isEmpty) return 'register_account_required'.tr;
    if (account.contains('@') && !GetUtils.isEmail(account)) {
      return 'register_email_invalid'.tr;
    }
    if (accountController.isPhoneInput) {
      final phoneError = Validators.phone(account);
      if (phoneError != null) return phoneError;
    } else if (!GetUtils.isEmail(account)) {
      final usernameError = Validators.username(account);
      if (usernameError != null) return usernameError;
    }
    final passwordError = Validators.password(passwordController.text);
    if (passwordError != null) return passwordError;
    if (confirmPasswordController.text.isEmpty) {
      return 'register_confirm_required'.tr;
    }
    if (passwordController.text != confirmPasswordController.text) {
      return 'register_password_mismatch'.tr;
    }
    return null;
  }

  /// The primary action first sends a code, then verifies and creates the
  /// account. A profile retry never repeats account creation or OTP verification.
  Future<void> register() async {
    if (isOtpStep.value) {
      await verifyAndRegister();
      return;
    }
    if (!_canSubmit()) return;
    if (isEmailStep.value) {
      await sendVerificationCode();
      return;
    }
    error.value = validate() ?? '';
    if (error.value.isNotEmpty) return;
    _registrationAccount = accountController.account;
    _password = passwordController.text;
    _isEmailAccount = GetUtils.isEmail(_registrationAccount);
    _isPhoneAccount = accountController.isPhoneInput;
    if (_isEmailAccount) {
      emailController.text = _registrationAccount;
      await sendVerificationCode();
    } else {
      await _run(() async {
        final response = await _service.register(
          account: _registrationAccount,
          password: _password,
          cancelToken: _cancelToken,
        );
        if (isClosed) return;
        if (!_isPhoneAccount) {
          // The register endpoint already created this username. Do not turn
          // a name with spaces into an invalid email or repeat profile setup.
          _completeRegistration();
          return;
        }
        _profileToken = AccessToken.normalize(response.token).value;
        if (_profileToken.isEmpty) {
          _profileToken = await _service.loginForProfile(
            account: _registrationAccount,
            password: _password,
            cancelToken: _cancelToken,
          );
          if (isClosed) return;
        }
        try {
          final profileEmail = _isPhoneAccount
              ? '${_registrationAccount.replaceAll(RegExp(r'\D'), '')}@piisiit.com'
              : '${_registrationAccount.trim()}@piisiit.com';
          await _service.saveProfile(
            token: _profileToken,
            username: !_isPhoneAccount ? _registrationAccount : null,
            email: profileEmail,
            phone: _isPhoneAccount ? _registrationAccount : null,
            cancelToken: _cancelToken,
          );
        } on RegistrationException {
          _profileToken = '';
          rethrow;
        }
        if (isClosed) return;
        _completeRegistration();
      });
    }
  }

  void _completeRegistration() {
    final account = _registrationAccount;
    final emailVerified = _isEmailAccount && _emailVerified;
    clearTemporaryData();
    _completedAccount = account;
    _completedEmailVerified = emailVerified;
    completed.value = true;
  }

  Future<void> sendVerificationCode() async {
    if (!_canSubmit() || _registrationAccount.isEmpty) return;
    final email = emailController.text.trim();
    if (!GetUtils.isEmail(email)) {
      error.value = 'register_email_invalid'.tr;
      return;
    }
    if (_lastSentEmail == email && resendIn.value > 0) {
      verificationEmail.value = email;
      error.value = '';
      isEmailStep.value = false;
      isOtpStep.value = true;
      return;
    }
    await _run(() async {
      await _service.sendOtp(email: email, cancelToken: _cancelToken);
      if (isClosed) return;
      verificationEmail.value = email;
      _lastSentEmail = email;
      _emailVerified = false;
      otpController.clear();
      _startResendCooldown();
      isEmailStep.value = false;
      isOtpStep.value = true;
    });
  }

  Future<void> resendOtp() async {
    if (!_canSubmit() || !isOtpStep.value || accountCreated.value) return;
    if (resendIn.value > 0) return;
    await _run(() async {
      await _service.sendOtp(
        email: verificationEmail.value,
        cancelToken: _cancelToken,
      );
      if (isClosed) return;
      _emailVerified = false;
      otpController.clear();
      _startResendCooldown();
    });
  }

  Future<void> verifyAndRegister() async {
    if (!_canSubmit() || !isOtpStep.value) return;
    if (!_emailVerified &&
        !RegExp(r'^[0-9]{6}$').hasMatch(otpController.text)) {
      error.value = 'register_otp_invalid'.tr;
      return;
    }
    if (accountController.account.isEmpty) {
      error.value = 'register_account_required'.tr;
      return;
    }
    if (!_isEmailAccount &&
        (GetUtils.isEmail(accountController.account) ||
            accountController.isPhoneInput != _isPhoneAccount)) {
      error.value = 'register_account_type_invalid'.tr;
      return;
    }
    if (_isPhoneAccount) {
      final phoneError = Validators.phone(accountController.account);
      if (phoneError != null) {
        error.value = phoneError;
        return;
      }
    }
    await _run(() async {
      if (!_emailVerified) {
        await _service.verifyEmailOtp(
          email: verificationEmail.value,
          otp: otpController.text,
          cancelToken: _cancelToken,
        );
        if (isClosed) return;
        _emailVerified = true;
      }
      if (!accountCreated.value) {
        final response = await _service.register(
          account: _registrationAccount,
          password: _password,
          cancelToken: _cancelToken,
        );
        if (isClosed) return;
        _profileToken = AccessToken.normalize(response.token).value;
        accountCreated.value = true;
        otpController.clear();
      }
      if (_profileToken.isEmpty) {
        _profileToken = await _service.loginForProfile(
          account: _registrationAccount,
          password: _password,
          cancelToken: _cancelToken,
        );
        if (isClosed) return;
      }
      try {
        await _service.saveProfile(
          token: _profileToken,
          username: !_isEmailAccount && !_isPhoneAccount
              ? accountController.account
              : null,
          email: verificationEmail.value,
          phone: _isPhoneAccount ? accountController.account : null,
          cancelToken: _cancelToken,
        );
      } on RegistrationException {
        // A temporary credential may expire while the user corrects details.
        // Authenticate again on the next retry, without recreating the account.
        _profileToken = '';
        rethrow;
      }
      if (isClosed) return;
      _completeRegistration();
    });
  }

  void finishRegistration() {
    if (!completed.value || isClosed || _openingLogin) return;
    _openingLogin = true;
    unawaited(
      Get.offAllNamed(Routes.LOGIN, arguments: {'account': _completedAccount}),
    );
  }

  void editDetails() {
    if (isLoading.value || accountCreated.value || isClosed) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _emailVerified = false;
    otpController.clear();
    error.value = '';
    isEmailStep.value = false;
    isOtpStep.value = false;
  }

  bool _canSubmit() {
    if (isLoading.value || isClosed || completed.value) return false;
    refreshCountdowns();
    return retryIn.value == 0;
  }

  Future<void> _run(Future<void> Function() action) async {
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    error.value = '';
    _cancelToken = CancelToken();
    try {
      await action();
    } on RegistrationException catch (failure) {
      if (isClosed) return;
      error.value = failure.message;
      if (failure.retryAfter != null) {
        _retryAt = _now().add(Duration(seconds: max(1, failure.retryAfter!)));
        _ensureTimer();
        refreshCountdowns();
      }
    } on DioException catch (failure) {
      if (!isClosed && !CancelToken.isCancel(failure)) {
        error.value = 'register_unexpected_error'.tr;
      }
    } catch (_) {
      if (!isClosed) error.value = 'register_unexpected_error'.tr;
    } finally {
      _cancelToken = null;
      if (!isClosed) isLoading.value = false;
    }
  }

  void _startResendCooldown() {
    _resendAt = _now().add(const Duration(seconds: 60));
    _ensureTimer();
    refreshCountdowns();
  }

  void _ensureTimer() {
    _timer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => refreshCountdowns(),
    );
  }

  void refreshCountdowns() {
    int secondsUntil(DateTime? date) => date == null
        ? 0
        : max(0, (date.difference(_now()).inMilliseconds / 1000).ceil());
    retryIn.value = secondsUntil(_retryAt);
    resendIn.value = secondsUntil(_resendAt);
    if (retryIn.value == 0 && resendIn.value == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void clearTemporaryData() {
    _completedAccount = null;
    _completedEmailVerified = false;
    _openingLogin = false;
    _timer?.cancel();
    _timer = null;
    _retryAt = null;
    _resendAt = null;
    _lastSentEmail = null;
    _password = '';
    _registrationAccount = '';
    _isEmailAccount = false;
    _isPhoneAccount = false;
    _profileToken = '';
    _emailVerified = false;
    for (final field in [
      accountController,
      emailController,
      passwordController,
      confirmPasswordController,
      otpController,
    ]) {
      field.clear();
    }
    verificationEmail.value = '';
    isEmailStep.value = false;
    isOtpStep.value = false;
    accountCreated.value = false;
    isPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
    error.value = '';
    retryIn.value = 0;
    resendIn.value = 0;
  }

  @override
  void onClose() {
    _cancelToken?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    clearTemporaryData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      accountController.dispose();
      emailController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
      otpController.dispose();
    });
    super.onClose();
  }
}
