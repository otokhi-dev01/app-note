import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/core/utils/validators.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';
import 'package:Note/features/auth/domain/repositories/auth_repository.dart';

class Login extends UseCase<AuthSession, LoginParams> {
  final AuthRepository _repository;

  const Login(this._repository);

  @override
  Future<Result<AuthSession>> call(LoginParams params) async {
    final invalid = Validators.phone(params.phone);
    if (invalid != null) return Err(ValidationFailure(invalid));
    if (params.password.isEmpty) {
      return const Err(ValidationFailure('Please enter your password.'));
    }

    return _repository.login(phone: params.phone, password: params.password);
  }
}

class LoginParams {
  final String phone;
  final String password;

  const LoginParams({required this.phone, required this.password});
}

class Register extends UseCase<AuthSession, RegisterParams> {
  final AuthRepository _repository;

  const Register(this._repository);

  @override
  Future<Result<AuthSession>> call(RegisterParams params) async {
    if (params.fullName.trim().isEmpty) {
      return const Err(ValidationFailure('Please enter your full name.'));
    }
    final invalid = Validators.phone(params.phone);
    if (invalid != null) return Err(ValidationFailure(invalid));

    final weak = Validators.password(params.password);
    if (weak != null) return Err(ValidationFailure(weak));

    if (params.password != params.confirmPassword) {
      return const Err(ValidationFailure('Passwords do not match.'));
    }

    return _repository.register(
      fullName: params.fullName.trim(),
      phone: params.phone,
      password: params.password,
      deviceName: params.deviceName,
      deviceType: params.deviceType,
    );
  }
}

class RegisterParams {
  final String fullName;
  final String phone;
  final String password;
  final String confirmPassword;
  final String deviceName;
  final String deviceType;

  const RegisterParams({
    required this.fullName,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.deviceName,
    required this.deviceType,
  });
}

class ForgotPassword extends UseCase<void, String> {
  final AuthRepository _repository;

  const ForgotPassword(this._repository);

  @override
  Future<Result<void>> call(String phone) => _repository.forgotPassword(phone);
}

class Logout extends UseCase<void, NoParams> {
  final AuthRepository _repository;

  const Logout(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.logout();
}

class LoadSession extends UseCase<AuthSession?, NoParams> {
  final AuthRepository _repository;

  const LoadSession(this._repository);

  @override
  Future<Result<AuthSession?>> call(NoParams params) =>
      _repository.loadSession();
}
