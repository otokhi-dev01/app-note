import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../models/auth_model.dart';

class SessionService extends GetxService {
  final _storage = const FlutterSecureStorage();
  
  final user = Rxn<UserData>();
  final token = RxnString();
  
  bool get isLoggedIn => token.value != null;

  @override
  void onInit() {
    super.onInit();
    loadSession();
  }

  Future<void> loadSession() async {
    token.value = await _storage.read(key: 'token');
    final userJson = await _storage.read(key: 'user');
    if (userJson != null) {
      try {
        user.value = UserData.fromJson(jsonDecode(userJson));
      } catch (_) {
        await clearSession();
      }
    }
  }

  Future<void> saveSession(String newToken, UserData userData) async {
    token.value = newToken;
    user.value = userData;
    await _storage.write(key: 'token', value: newToken);
    await _storage.write(key: 'user', value: jsonEncode(userData.toJson()));
  }

  Future<void> clearSession() async {
    token.value = null;
    user.value = null;
    await _storage.deleteAll();
  }
}
