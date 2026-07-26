import 'package:dio/dio.dart' as dio;
import '../providers/api_provider.dart';
import '../models/user_model.dart';

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

  Future<UserModel?> getProfile() async {
    try {
      final response = await get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        return UserModel.fromJson(data);
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
