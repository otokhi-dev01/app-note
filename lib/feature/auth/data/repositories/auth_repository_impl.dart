import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  const AuthRepositoryImpl({
    required this.apiClient,
    required this.tokenStorage,
  });

  @override
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    final dynamic response = await apiClient.post(
      ApiEndpoints.login,
      requiresAuth: false,
      useAuthBaseUrl: true,
      body: <String, dynamic>{
        'phone': phone.trim(),
        'password': password,
      },
    );

    _ensureBusinessRequestSucceeded(response);

    final String? token = _extractToken(response);

    if (token == null || token.trim().isEmpty) {
      throw const ApiException(
        message:
        'The login response does not contain an authentication token.',
      );
    }

    await tokenStorage.saveToken(token);
  }

  @override
  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    required String deviceName,
    required String deviceType,
  }) async {
    final dynamic response = await apiClient.post(
      ApiEndpoints.register,
      requiresAuth: false,
      useAuthBaseUrl: true,
      body: <String, dynamic>{
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'password': password,
        'deviceName': deviceName.trim(),
        'deviceType': deviceType.trim(),
      },
    );

    _ensureBusinessRequestSucceeded(response);
  }

  @override
  Future<void> logout() {
    return tokenStorage.deleteToken();
  }

  @override
  Future<bool> isLoggedIn() {
    return tokenStorage.hasToken();
  }

  void _ensureBusinessRequestSucceeded(
      dynamic response,
      ) {
    if (response is! Map) {
      return;
    }

    final int? code = _toInt(
      response['code'] ?? response['statusCode'],
    );

    if (code == null || code < 400) {
      return;
    }

    throw ApiException(
      message:
      response['message']?.toString() ??
          response['error']?.toString() ??
          'The request failed.',
      statusCode: code,
      responseData: response,
    );
  }

  String? _extractToken(dynamic response) {
    if (response is! Map) {
      return null;
    }

    final dynamic data = response['data'];

    if (data is Map) {
      final String? nestedToken =
          data['token']?.toString() ??
              data['accessToken']?.toString() ??
              data['access_token']?.toString();

      if (nestedToken != null &&
          nestedToken.trim().isNotEmpty) {
        return nestedToken;
      }
    }

    return response['token']?.toString() ??
        response['accessToken']?.toString() ??
        response['access_token']?.toString();
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }
}