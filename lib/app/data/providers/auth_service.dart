import 'package:flutter/foundation.dart';
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

    final authResponse = AuthResponse.fromJson(response.data);

    if (kDebugMode) {
      debugPrint("Login successful");
    }

    return authResponse;
  }

  Future<void> register(RegisterRequest request) async {
    await _api.dio.post("/api/auth/register", data: request.toJson());

    if (kDebugMode) {
      debugPrint("Registration successful");
    }
  }
}
