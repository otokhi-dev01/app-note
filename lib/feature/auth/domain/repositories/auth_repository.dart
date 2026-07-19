abstract class AuthRepository {
  Future<void> login({
    required String phone,
    required String password,
  });

  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    required String deviceName,
    required String deviceType,
  });

  Future<void> logout();

  Future<bool> isLoggedIn();
}