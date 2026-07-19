import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const String _tokenKey = 'access_token';

  final FlutterSecureStorage _storage =
  const FlutterSecureStorage();

  Future<void> saveToken(String token) {
    return _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() {
    return _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final String? token = await readToken();

    return token != null && token.trim().isNotEmpty;
  }
}