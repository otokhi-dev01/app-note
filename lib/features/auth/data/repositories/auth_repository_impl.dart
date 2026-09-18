import 'package:flutter/foundation.dart';
import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/error/guard.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';
import 'package:Note/features/auth/domain/entities/security_question.dart';
import 'package:Note/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SessionStorage _session;

  const AuthRepositoryImpl(this._remote, this._session);

  @override
  Future<Result<AuthSession>> login({
    required String account,
    required String password,
  }) => guard(() async {
    final response = await _remote.login(account, password);
    return _persist(response);
  });

  @override
  Future<Result<void>> register({
    required String account,
    required String password,
  }) => guard(() async {
    final response = await _remote.register(account, password);
    if (!response.isSuccess) {
      throw ServerException(
        response.message.isEmpty
            ? 'Could not create your account. Please try again.'
            : response.message,
        statusCode: response.code,
      );
    }
  });

  @override
  Future<Result<void>> forgotPassword(String account) =>
      guard(() => _remote.forgotPassword(account));

  @override
  Future<Result<String>> verifyPasswordOtp(String account, String otp) =>
      guard(() => _remote.verifyPasswordOtp(account, otp));

  @override
  Future<Result<List<SecurityQuestion>>> getSecurityQuestions() =>
      guard(_remote.getSecurityQuestions);

  @override
  Future<Result<String>> verifySecurityAnswers(
    String account,
    List<SecurityAnswer> answers,
  ) => guard(() => _remote.verifySecurityAnswers(account, answers));

  @override
  Future<Result<void>> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) => guard(() async {
    await _remote.resetPassword(
      resetToken: resetToken,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    await _session.clearSession();
  });

  @override
  Future<Result<void>> logout() => guard(() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Best-effort server revocation: still sign out locally even if the
      // device is offline or the call otherwise fails.
    }
    await _session.clearSession();
  });

  @override
  Future<Result<void>> deleteAccount({required String password}) =>
      guard(() async {
        await _remote.deleteAccount(password);
        await _session.clearSession();
      });

  @override
  Future<Result<AuthSession?>> loadSession() => guard(() async {
    await _session.loadSession();
    final token = _session.token.value;
    final user = _session.user.value;
    if (token == null || token.isEmpty) return null;
    return AuthSession(token: token, user: user ?? const UserData());
  });

  /// The API answers 200 with an error code in the body, so success is decided
  /// here rather than by the HTTP status.
  Future<AuthSession> _persist(AuthResponse response) async {
    if (kDebugMode) {
      debugPrint('[AUTH] Persisting response: isSuccess=${response.isSuccess} token.isEmpty=${response.token.isEmpty}');
    }
    if (!response.isSuccess || response.token.isEmpty) {
      throw ServerException(
        response.message.isEmpty
            ? 'Could not sign you in. Please try again.'
            : response.message,
        statusCode: response.code,
      );
    }
    await _session.saveSession(response.token, response.user);
    return AuthSession(token: response.token, user: response.user);
  }
}
