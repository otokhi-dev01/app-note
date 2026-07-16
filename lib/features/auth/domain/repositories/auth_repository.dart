import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<void> get ready;

  AuthUser? get user;
  bool get isLoggedIn;
  String? get accountScopeId;
  String? get lastError;

  Future<bool> login(String phone, String password);
  Future<bool> signup(String phone, String password);
  Future<void> logout();
}
