import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_session.dart';
import '../models/auth_session_model.dart';

class AuthSessionStorage {
  static const String _sessionKey = 'auth_session';

  final FlutterSecureStorage _storage;

  const AuthSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession(AuthSession session) {
    final AuthSessionModel model = AuthSessionModel.fromSession(session);

    return _storage.write(key: _sessionKey, value: jsonEncode(model.toJson()));
  }

  Future<AuthSession?> readSession() async {
    try {
      final String? value = await _storage.read(key: _sessionKey);

      if (value == null || value.trim().isEmpty) {
        return null;
      }

      final dynamic decoded = jsonDecode(value);
      if (decoded is! Map) {
        throw const FormatException('Invalid stored authentication session.');
      }

      return AuthSessionModel.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() {
    return _storage.delete(key: _sessionKey);
  }
}
