import 'package:dio/dio.dart' as dio;
import '../providers/api_provider.dart';

class AuthRepository extends ApiProvider {
  Future<dio.Response> login(String phone, String password) async {
    return await post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
  }

  Future<dio.Response> register({
    required String fullName,
    required String phone,
    required String password,
    required String deviceName,
    String deviceType = 'android',
  }) async {
    return await post('/auth/register', data: {
      'fullName': fullName,
      'phone': phone,
      'password': password,
      'deviceName': deviceName,
      'deviceType': deviceType,
    });
  }
}
