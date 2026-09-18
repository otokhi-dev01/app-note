import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';
import 'package:Note/features/auth/domain/entities/security_question.dart';

/// Raw `/api/auth` transport.
class AuthRemoteDataSource extends GetxService {
  final ApiClient _api;
  final AuthDeviceService _deviceService;

  AuthRemoteDataSource({ApiClient? api, AuthDeviceService? deviceService})
    : _api = api ?? Get.find<ApiClient>(),
      _deviceService = deviceService ?? AuthDeviceService();

  Future<AuthResponse> login(String account, String password) =>
      _submitCredentials(
        '${AppConstants.authBaseUrl}${AppConstants.loginEndpoint}',
        account,
        password,
      );

  Future<AuthResponse> register(String account, String password) =>
      _submitCredentials(
        '${AppConstants.authBaseUrl}${AppConstants.registerEndpoint}',
        account,
        password,
      );

  Future<AuthResponse> _submitCredentials(
    String url,
    String account,
    String password,
  ) async {
    try {
      final device = await _deviceService.read();
      final request = AuthCredentialsRequest(
        account: account,
        password: password,
        clientDeviceId: device.clientDeviceId,
        appVersion: device.appVersion,
        deviceName: device.deviceName,
        platform: device.platform,
        deviceModel: device.deviceModel,
      );
      if (kDebugMode) {
        debugPrint('[AUTH] Calling: $url');
      }
      final response = await _api.dio.post(
        url,
        data: request.toJson(),
        options: dio.Options(
          headers: {'Accept': '*/*', 'Content-Type': 'application/json'},
          extra: {'requiresAuth': false},
        ),
      );
      if (kDebugMode) {
        debugPrint('[AUTH] Response: status=${response.statusCode}');
      }
      if (response.data is! Map) {
        throw const ServerException(
          'The account server returned an invalid response. Please try again.',
        );
      }
      if (url.endsWith(AppConstants.loginEndpoint)) {
        _checkCredentialRejection(response.data, response.statusCode);
      }
      return AuthResponse.fromJson(
        Map<String, dynamic>.from(response.data),
        statusCode: response.statusCode,
      );
    } on dio.DioException catch (e) {
      if (url.endsWith(AppConstants.loginEndpoint)) {
        _checkCredentialRejection(e.response?.data, e.response?.statusCode);
      }
      throw ApiErrorParser.toException(e);
    }
  }

  /// The live server currently labels invalid credentials as HTTP 500.
  /// Match only its explicit credential rejection, never arbitrary 5xx errors.
  void _checkCredentialRejection(dynamic body, int? statusCode) {
    if (body is! Map || (body['success'] ?? body['Success']) == true) return;
    final message = (body['message'] ?? body['Message'])
        ?.toString()
        .trim()
        .toLowerCase();
    if (message == 'invalid credential!' ||
        message == 'invalid credentials!' ||
        message == 'invalid account or password.') {
      if (kDebugMode) {
        debugPrint('[AUTH] Credential rejection: status=$statusCode');
      }
      throw const UnauthorizedException(
        'Invalid account or password. Please check your details and try again.',
      );
    }
  }

  /// Revokes the current device's session server-side. Callers should still
  /// clear the local session even if this throws — the user asked to sign
  /// out and must not be left stuck signed in locally over a network hiccup.
  Future<void> logout() async {
    try {
      await _api.dio.post(
        '${AppConstants.authBaseUrl}${AppConstants.logoutEndpoint}',
      );
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Permanently deletes the account server-side — the backend must actually
  /// erase (or irrecoverably anonymize) the user's record and their data,
  /// not just flip a disabled/inactive flag. [password] reauthenticates the
  /// request so a stolen/unlocked session token alone can't destroy the
  /// account.
  Future<void> deleteAccount(String password) async {
    try {
      await _api.dio.post(
        '${AppConstants.authBaseUrl}/delete-account',
        data: {'password': password},
      );
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Contract verified against the Chat server's Swagger document.
  Future<void> forgotPassword(String account) async {
    await _passwordRequest(AppConstants.forgotPasswordEndpoint, {
      'account': account,
    });
  }

  Future<String> verifyPasswordOtp(String account, String otp) async {
    final response = await _passwordRequest(
      AppConstants.verifyPasswordOtpEndpoint,
      {'account': account, 'otp': otp},
    );
    return _readResetToken(response);
  }

  Future<List<SecurityQuestion>> getSecurityQuestions() async {
    final response = await _passwordRequest(
      AppConstants.securityQuestionsEndpoint,
      {},
      method: 'GET',
    );
    final data = response['data'] ?? response['Data'];
    if (data is! List || data.isEmpty) {
      throw const ServerException(
        'Security questions are unavailable. Please try again.',
      );
    }
    final questions = <SecurityQuestion>[];
    final ids = <String>{};
    for (final item in data) {
      if (item is! Map ||
          item['id'] is! String ||
          item['question'] is! String) {
        throw const ServerException(
          'The server returned invalid security questions.',
        );
      }
      final id = (item['id'] as String).trim();
      final question = (item['question'] as String).trim();
      if (id.isEmpty || question.isEmpty || !ids.add(id)) {
        throw const ServerException(
          'The server returned invalid security questions.',
        );
      }
      questions.add(SecurityQuestion(id: id, question: question));
    }
    return questions;
  }

  Future<String> verifySecurityAnswers(
    String account,
    List<SecurityAnswer> answers,
  ) async {
    final response = await _passwordRequest(
      AppConstants.verifySecurityAnswersEndpoint,
      {
        'account': account,
        'answers': [
          for (final answer in answers)
            {'questionId': answer.questionId, 'answer': answer.answer},
        ],
      },
    );
    return _readResetToken(response);
  }

  String _readResetToken(Map<String, dynamic> response) {
    final data = response['data'] ?? response['Data'];
    final token = data is Map
        ? data['resetToken'] ?? data['ResetToken']
        : response['resetToken'] ?? response['ResetToken'];
    if (token is! String || token.trim().isEmpty) {
      throw const ServerException(
        'The server did not return a password reset token. Please try again.',
      );
    }
    return token;
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _passwordRequest(AppConstants.resetPasswordEndpoint, {
      'resetToken': resetToken,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  /// Recovery is public even when opened from a signed-in profile. Never
  /// attach a session token or run silent session recovery for these requests.
  Future<Map<String, dynamic>> _passwordRequest(
    String endpoint,
    Map<String, dynamic> body, {
    String method = 'POST',
  }) async {
    try {
      final response = await _api.dio.request(
        '${AppConstants.authBaseUrl}$endpoint',
        data: method == 'GET' ? null : body,
        options: dio.Options(method: method, extra: {'requiresAuth': false}),
      );
      final raw = response.data;
      if (raw is! Map) {
        throw const ServerException(
          'The server returned an invalid recovery response.',
        );
      }
      final json = Map<String, dynamic>.from(raw);
      // The account API uses an explicit success envelope; a 200 alone does
      // not mean the code was sent, verified, or the password changed.
      if ((json['success'] ?? json['Success']) != true) {
        throw ServerException(
          ApiErrorParser.messageFrom(
            json,
            fallback: 'Password recovery failed. Please try again.',
          ),
          statusCode: response.statusCode,
        );
      }
      return json;
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }
}
