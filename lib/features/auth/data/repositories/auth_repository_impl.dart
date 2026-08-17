import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/error/guard.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';
import 'package:Note/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SessionStorage _session;

  const AuthRepositoryImpl(this._remote, this._session);

  @override
  Future<Result<AuthSession>> login({
    required String phone,
    required String password,
  }) => guard(() async {
    final response = await _remote.login(phone, password);
    return _persist(response);
  });

  @override
  Future<Result<AuthSession>> register({
    required String fullName,
    required String phone,
    required String password,
    required String deviceName,
    required String deviceType,
  }) => guard(() async {
    final response = await _remote.register(
      RegisterRequest(
        fullName: fullName,
        phone: phone,
        password: password,
        deviceName: deviceName,
        deviceType: deviceType,
      ),
    );
    return _persist(response);
  });

  @override
  Future<Result<void>> forgotPassword(String phone) =>
      guard(() => _remote.forgotPassword(phone));

  @override
  Future<Result<void>> logout() => guard(() => _session.clearSession());

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
