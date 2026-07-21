import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<void> login({required String phone, required String password});

  /// Registers credentials and reports whether the response also authenticated
  /// the new account by returning an access token.
  Future<bool> register({required String phone, required String password});

  Future<void> logout();

  Future<bool> isLoggedIn();

  Future<AuthSession?> getSession();
}
