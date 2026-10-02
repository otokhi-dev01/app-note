import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/utils/validators.dart';
import 'package:Note/features/auth/data/services/registration_service.dart';
import 'package:Note/routes/app_pages.dart';

class RegistrationController extends GetxController
    with WidgetsBindingObserver {
  RegistrationController(this._service, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final RegistrationService _service;
  final DateTime Function() _now;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;
  final retryIn = 0.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final error = ''.obs;
  final completed = false.obs;
  DateTime? _retryAt;
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
    if (!GetUtils.isEmail(emailController.text.trim())) {
      return 'Please enter a valid email address.';
    }
    final passwordError = Validators.password(passwordController.text);
    if (passwordError != null) return passwordError;
    if (confirmPasswordController.text.isEmpty) {
      return 'Please confirm your password.';
    }
    if (passwordController.text != confirmPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> register() async {
    if (isLoading.value || isClosed || completed.value) return;
    refreshCountdowns();
    if (retryIn.value > 0) return;
    error.value = validate() ?? '';
    if (error.value.isNotEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    _cancelToken = CancelToken();
    try {
      await _service.register(
        account: emailController.text,
        password: passwordController.text,
        cancelToken: _cancelToken,
      );
      if (isClosed) return;
      completed.value = true;
      clearTemporaryData();
      AppSnackbar.success('success_title'.tr, 'register_success_message'.tr);
      // Let field focus notifications finish before replacing the auth stack.
      await WidgetsBinding.instance.endOfFrame;
      if (!isClosed) unawaited(Get.offAllNamed(Routes.LOGIN));
    } on RegistrationException catch (failure) {
      if (isClosed) return;
      error.value = failure.message;
      if (failure.retryAfter != null) {
        _retryAt = _now().add(Duration(seconds: max(1, failure.retryAfter!)));
        refreshCountdowns();
        _timer?.cancel();
        _timer = Timer.periodic(
          const Duration(seconds: 1),
          (_) => refreshCountdowns(),
        );
      }
    } on DioException catch (failure) {
      if (!isClosed && !CancelToken.isCancel(failure)) {
        error.value = 'Registration could not be completed. Please try again.';
      }
    } catch (_) {
      if (!isClosed) {
        error.value = 'Registration could not be completed. Please try again.';
      }
    } finally {
      _cancelToken = null;
      if (!isClosed) isLoading.value = false;
    }
  }

  void refreshCountdowns() {
    retryIn.value = _retryAt == null
        ? 0
        : max(0, (_retryAt!.difference(_now()).inMilliseconds / 1000).ceil());
    if (retryIn.value == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void clearTemporaryData() {
    _timer?.cancel();
    _timer = null;
    _retryAt = null;
    for (final field in [
      emailController,
      passwordController,
      confirmPasswordController,
    ]) {
      field.clear();
    }
    isPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
    error.value = '';
    retryIn.value = 0;
  }

  @override
  void onClose() {
    _cancelToken?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    clearTemporaryData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      emailController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
    });
    super.onClose();
  }
}
