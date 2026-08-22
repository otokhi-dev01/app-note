import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;

import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/network/api_capabilities.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';

/// Raw `/api/auth` transport.
class AuthRemoteDataSource extends GetxService {
  final ApiClient _api = Get.find<ApiClient>();

  Future<AuthResponse> login(String phone, String password) async {
    try {
      final response = await _api.dio.post(
        '/api/auth/login',
        data: {'phone': phone, 'password': password},
      );
      return AuthResponse.fromJson(Map<String, dynamic>.from(response.data));
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _api.dio.post(
        '/api/auth/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(Map<String, dynamic>.from(response.data));
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
        '/api/auth/delete-account',
        data: {'password': password},
      );
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Not supported: no `/api/auth/forgot-password` route exists.
  /// See [ApiCapabilities.forgotPassword].
  ///
  /// This previously faked a successful send, which told users a reset link
  /// was on its way when nothing was ever dispatched.
  Future<void> forgotPassword(String phone) async {
    throw const UnsupportedFeatureException(
      'Password reset is not available on the server yet. '
      'Please contact support to reset your password.',
    );
  }
}
