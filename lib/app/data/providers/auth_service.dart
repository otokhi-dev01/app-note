import 'package:get/get.dart' hide Response;
import '../models/auth_model.dart';
import 'api_service.dart';

class AuthService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  Future<AuthResponse> login(String phone, String password) async {
    final response = await _api.dio.post(
      "/api/auth/login",
      data: {"phone": phone, "password": password},
    );

    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _api.dio.post(
      "/api/auth/register",
      data: request.toJson(),
    );
    
    return AuthResponse.fromJson(response.data);
  }

  /// Not supported: the API exposes no /api/auth/forgot-password route.
  /// See [ApiCapabilities.forgotPassword].
  ///
  /// This previously faked a successful send, which told users a reset link
  /// was on its way when nothing was ever dispatched.
  Future<bool> forgotPassword(String phone) async {
    throw const ApiUnsupportedException(
      'Password reset is not available on the server yet. '
      'Please contact support to reset your password.',
    );
  }
}
