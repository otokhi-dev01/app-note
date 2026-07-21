import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_parser.dart';
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
    final String cleanPhone = phone.trim();

    if (cleanPhone.isEmpty) {
      throw const ApiException(message: 'Phone number is required.');
    }

    if (password.isEmpty) {
      throw const ApiException(message: 'Password is required.');
    }

    final dynamic response = await apiClient.post(
      ApiEndpoints.login,
      requiresAuth: false,
      useAuthBaseUrl: true,
      body: <String, dynamic>{
        'phone': cleanPhone,
        'password': password,
      },
    );

    ApiParser.ensureSuccess(
      response,
      fallbackMessage: 'Login failed.',
    );

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
    final String cleanFullName = fullName.trim();
    final String cleanPhone = phone.trim();

    if (cleanFullName.isEmpty) {
      throw const ApiException(message: 'Full name is required.');
    }

    if (cleanPhone.isEmpty) {
      throw const ApiException(message: 'Phone number is required.');
    }

    if (password.isEmpty) {
      throw const ApiException(message: 'Password is required.');
    }

    final dynamic response = await apiClient.post(
      ApiEndpoints.register,
      requiresAuth: false,
      useAuthBaseUrl: true,
      body: <String, dynamic>{
        'fullName': cleanFullName,
        'phone': cleanPhone,
        'password': password,
        'deviceName': deviceName.trim(),
        'deviceType': deviceType.trim(),
      },
    );

    ApiParser.ensureSuccess(
      response,
      fallbackMessage: 'Registration failed.',
    );

    final String? token = _extractToken(response);

    if (token != null && token.isNotEmpty) {
      await tokenStorage.saveToken(token);
    }
  }

  @override
  Future<void> logout() {
    return tokenStorage.deleteToken();
  }

  @override
  Future<bool> isLoggedIn() {
    return tokenStorage.hasToken();
  }

  String? _extractToken(dynamic response) {
    final dynamic token = ApiParser.findValue(
      response,
      const <String>['token', 'accessToken', 'access_token'],
    );

    final String cleanToken = token?.toString().trim() ?? '';

    return cleanToken.isEmpty ? null : cleanToken;
  }
}
