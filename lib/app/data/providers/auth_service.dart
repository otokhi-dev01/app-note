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

    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _api.dio.post(
      "/api/auth/register",
      data: request.toJson(),
    );
    
    return AuthResponse.fromJson(response.data);
  }

  Future<bool> forgotPassword(String phone) async {
    try {
      // Placeholder for forgot password API
      // final response = await _api.dio.post("/api/auth/forgot-password", data: {"phone": phone});
      // return response.statusCode == 200;
      
      // Simulating a network call for now
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint("Forgot password error: $e");
      return false;
    }
  }
}
