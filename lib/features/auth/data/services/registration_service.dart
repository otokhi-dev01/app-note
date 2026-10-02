import 'package:dio/dio.dart';

import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';

class RegistrationException implements Exception {
  const RegistrationException(this.message, {this.retryAfter});
  final String message;
  final int? retryAfter;
}

/// The documented Chat registration endpoint. Never persists returned tokens.
class RegistrationService {
  RegistrationService(ApiClient api, {AuthDeviceService? deviceService})
    : _dio = api.dio,
      _deviceService = deviceService ?? AuthDeviceService();

  final Dio _dio;
  final AuthDeviceService _deviceService;

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

  RegistrationException _failure(dynamic body, int? status, {int? retryAfter}) {
    final fallback = switch (status) {
      409 => 'This email is already registered. Please sign in.',
      429 => 'Too many attempts. Please wait before trying again.',
      400 || 422 => 'Please check your email and password and try again.',
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
