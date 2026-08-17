import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'package:Note/features/auth/data/models/auth_model.dart';

/// Persists the bearer token and signed-in user in the platform keystore.
///
/// Exposed as observables so the API client can attach the token and the UI can
/// react to sign-in/sign-out without a separate event bus.
class SessionStorage extends GetxService {
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
    try {
      token.value = await _storage.read(key: 'token');
      final userJson = await _storage.read(key: 'user');
      if (userJson != null) {
        user.value = UserData.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      // A corrupt payload or an unavailable keystore (locked device, missing
      // plugin in tests) must not crash startup — treat it as signed out.
      if (kDebugMode) debugPrint('[SESSION] Could not restore session: $e');
      token.value = null;
      user.value = null;
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
