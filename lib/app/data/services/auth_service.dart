import 'package:get/get.dart' hide Response;
import '../models/auth_model.dart';
import 'api_service.dart';

class AuthService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  Future<AuthResponse> login(String phone, String password) async {
    try {
      final response = await _api.dio.post("/api/auth/login", data: {
        "phone": phone,
        "password": password,
      });
      print("Login Response: ${response.data}");
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }

  Future<void> register(RegisterRequest request) async {
    await _api.dio.post("/api/auth/register", data: request.toJson());
  }
}
