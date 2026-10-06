import 'package:dio/dio.dart';

import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/core/network/access_token.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';

class RegistrationException implements Exception {
  const RegistrationException(this.message, {this.retryAfter});
  final String message;
  final int? retryAfter;
}

/// The documented Chat registration endpoint. Session persistence stays in the
/// registration controller so this service remains usable in tests and other
/// auth flows.
class RegistrationService {
  RegistrationService(ApiClient api, {AuthDeviceService? deviceService})
    : _dio = api.dio,
      _deviceService = deviceService ?? AuthDeviceService();

  final Dio _dio;
  final AuthDeviceService _deviceService;

  /// Some register responses omit tokens. Authenticate to obtain a credential
  /// that can complete profile setup or open the app after signup.
  Future<String> loginForProfile({
    required String account,
    required String password,
    CancelToken? cancelToken,
  }) async {
    final device = await _deviceService.read();
    final cancellation = cancelToken?.cancelError;
    if (cancellation != null) throw cancellation;
    try {
      final response = await _dio.post(
        '${AppConstants.authBaseUrl}${AppConstants.loginEndpoint}',
        data: {
          'account': account.trim(),
          'password': password,
          'clientDeviceId': device.clientDeviceId,
          'deviceName': device.deviceName,
          'platform': device.platform,
          'deviceModel': device.deviceModel,
          'appVersion': device.appVersion,
        },
        cancelToken: cancelToken,
        options: Options(extra: {'requiresAuth': false}),
      );
      final auth = _readAuthResponse(response);
      final token = AccessToken.normalize(auth.token).value;
      if (token.isEmpty) {
        throw const RegistrationException(
          'Your account was created, but profile setup could not be authorized. Please try again.',
        );
      }
      return token;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw _failure(
        error.response?.data,
        error.response?.statusCode,
        retryAfter: int.tryParse(
          error.response?.headers.value('retry-after') ?? '',
        ),
      );
    }
  }

  Future<void> saveProfile({
    required String token,
    String? username,
    String? email,
    String? phone,
    CancelToken? cancelToken,
  }) async {
    // Keep the new account's credential separate from any current app session.
    // Shared auth interceptors intentionally strip caller-supplied credentials.
    final profileClient = Dio(_dio.options.copyWith())
      ..httpClientAdapter = _dio.httpClientAdapter;
    try {
      final response = await profileClient.post(
        '${AppConstants.userApiUrl}/profile/save',
        data: {
          if (username != null && username.trim().isNotEmpty)
            'username': username.trim(),
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
        cancelToken: cancelToken,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _readAuthResponse(response);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw _failure(
        error.response?.data,
        error.response?.statusCode,
        retryAfter: int.tryParse(
          error.response?.headers.value('retry-after') ?? '',
        ),
      );
    }
  }

  Future<void> sendOtp({
    required String email,
    CancelToken? cancelToken,
  }) async {
    await _otpRequest(AppConstants.signupSendOtpEndpoint, {
      'email': email.trim(),
    }, cancelToken);
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
    CancelToken? cancelToken,
  }) async {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp.trim())) {
      throw const RegistrationException('Please enter the 6-digit email code.');
    }
    await _otpRequest(AppConstants.verifyEmailOtpEndpoint, {
      'email': email.trim(),
      'otp': otp.trim(),
    }, cancelToken);
  }

  Future<void> _otpRequest(
    String endpoint,
    Map<String, String> body,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authBaseUrl}$endpoint',
        data: body,
        cancelToken: cancelToken,
        options: Options(extra: {'requiresAuth': false}),
      );
      final data = response.data;
      if (data is! Map || (data['success'] ?? data['Success']) != true) {
        throw _failure(data, response.statusCode);
      }
      _readAuthResponse(response);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw _failure(
        error.response?.data,
        error.response?.statusCode,
        retryAfter: int.tryParse(
          error.response?.headers.value('retry-after') ?? '',
        ),
      );
    }
  }

  Future<AuthResponse> register({
    required String account,
    required String password,
    CancelToken? cancelToken,
  }) async {
    try {
      final device = await _deviceService.read();
      final cancellation = cancelToken?.cancelError;
      if (cancellation != null) throw cancellation;
      final response = await _dio.post(
        '${AppConstants.authBaseUrl}${AppConstants.registerEndpoint}',
        data: {
          'account': account.trim(),
          'password': password,
          'clientDeviceId': device.clientDeviceId,
          'deviceName': device.deviceName,
          'platform': device.platform,
          'deviceModel': device.deviceModel,
          'appVersion': device.appVersion,
        },
        cancelToken: cancelToken,
        options: Options(extra: {'requiresAuth': false}),
      );
      // A transport-level 200 is not evidence that the account was created.
      // In particular, message-only/null-data bodies must never unlock success.
      final body = response.data;
      if (body is! Map || (body['success'] ?? body['Success']) != true) {
        throw _failure(body, response.statusCode);
      }
      return _readAuthResponse(response);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw _failure(
        error.response?.data,
        error.response?.statusCode,
        retryAfter: int.tryParse(
          error.response?.headers.value('retry-after') ?? '',
        ),
      );
    }
  }

  AuthResponse _readAuthResponse(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body.isEmpty) {
      throw const RegistrationException(
        'The server returned an invalid registration response. Please try again.',
      );
    }
    final auth = AuthResponse.fromJson(
      Map<String, dynamic>.from(body),
      statusCode: response.statusCode,
    );
    final errors =
        body['errors'] ?? body['Errors'] ?? body['error'] ?? body['Error'];
    final hasErrors =
        errors != null &&
        errors.toString().isNotEmpty &&
        errors.toString() != '{}' &&
        errors.toString() != '[]';
    if (!auth.isSuccess || auth.code >= 400 || hasErrors) {
      throw _failure(body, response.statusCode);
    }
    return auth;
  }

  RegistrationException _failure(dynamic body, int? status, {int? retryAfter}) {
    final fallback = switch (status) {
      409 => 'These account details are already in use. Please check them.',
      429 => 'Too many attempts. Please wait before trying again.',
      400 ||
      422 => 'Please check your details or verification code and try again.',
      404 || 405 => 'Registration is unavailable. Please contact support.',
      null =>
        'Could not reach the server. Check your connection and try again.',
      _ => 'Registration could not be completed. Please try again.',
    };
    return RegistrationException(
      ApiErrorParser.messageFrom(body, fallback: fallback),
      retryAfter: status == 429 ? (retryAfter ?? 60) : null,
    );
  }
}
