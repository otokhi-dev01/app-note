import 'package:Note/core/error/result.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  /// Authenticates and persists the session so later requests are authorized.
  Future<Result<AuthSession>> login({
    required String account,
    required String password,
  });

  /// Creates an account; the user signs in separately after registration.
  Future<Result<void>> register({
    required String account,
    required String password,
  });

  /// Requests password-recovery instructions for the account phone number.
  Future<Result<void>> forgotPassword(String phone);

  Future<Result<void>> logout();

  /// Permanently deletes the signed-in user's account and every record tied
  /// to it on the server — not a deactivation/soft-delete. [password]
  /// reauthenticates the request. Clears the local session on success.
  Future<Result<void>> deleteAccount({required String password});

  /// Restores a persisted session on cold start, if there is one.
  Future<Result<AuthSession?>> loadSession();
}
