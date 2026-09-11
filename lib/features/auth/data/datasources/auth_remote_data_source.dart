import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;

import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';

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
      final response = await _api.dio.post(
        url,
        data: request.toJson(),
        options: dio.Options(
          headers: {'Accept': '*/*'},
          extra: {'requiresAuth': false},
        ),
      );
      return AuthResponse.fromJson(
        Map<String, dynamic>.from(response.data),
        statusCode: response.statusCode,
      );
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
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
        '/api/auth/delete-account',
        data: {'password': password},
      );
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  Future<void> forgotPassword(String phone) async {
    try {
      await _api.dio.post('/api/auth/forgot-password', data: {'phone': phone});
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const UnsupportedFeatureException(
          'Password recovery is not available on the server yet. '
          'Please contact support for help accessing your account.',
        );
      }
      throw ApiErrorParser.toException(e);
    }
  }
}
