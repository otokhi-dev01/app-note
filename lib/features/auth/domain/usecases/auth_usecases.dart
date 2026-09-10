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
    if (params.account.trim().isEmpty) {
      return const Err(ValidationFailure('Please enter your account.'));
    }
    if (params.password.isEmpty) {
      return const Err(ValidationFailure('Please enter your password.'));
    }

    return _repository.login(
      account: params.account.trim(),
      password: params.password,
    );
  }
}

class LoginParams {
  final String account;
  final String password;

  const LoginParams({required this.account, required this.password});
}

class Register extends UseCase<void, RegisterParams> {
  final AuthRepository _repository;

  const Register(this._repository);

  @override
  Future<Result<void>> call(RegisterParams params) async {
    if (params.account.trim().isEmpty) {
      return const Err(ValidationFailure('Please enter your account.'));
    }

    final weak = Validators.password(params.password);
    if (weak != null) return Err(ValidationFailure(weak));

    if (params.password != params.confirmPassword) {
      return const Err(ValidationFailure('Passwords do not match.'));
    }

    return _repository.register(
      account: params.account.trim(),
      password: params.password,
    );
  }
}

class RegisterParams {
  final String account;
  final String password;
  final String confirmPassword;

  const RegisterParams({
    required this.account,
    required this.password,
    required this.confirmPassword,
  });
}

class ForgotPassword extends UseCase<void, String> {
  final AuthRepository _repository;

  const ForgotPassword(this._repository);

  @override
  Future<Result<void>> call(String phone) {
    final normalizedPhone = phone.trim();
    final invalid = Validators.phone(normalizedPhone);
    if (invalid != null) {
      return Future.value(Err(ValidationFailure(invalid)));
    }
    return _repository.forgotPassword(normalizedPhone);
  }
}

class Logout extends UseCase<void, NoParams> {
  final AuthRepository _repository;

  const Logout(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.logout();
}

class DeleteAccount extends UseCase<void, String> {
  final AuthRepository _repository;

  const DeleteAccount(this._repository);

  @override
  Future<Result<void>> call(String password) {
    if (password.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Please enter your password to confirm.')),
      );
    }
    return _repository.deleteAccount(password: password);
  }
}

class LoadSession extends UseCase<AuthSession?, NoParams> {
  final AuthRepository _repository;

  const LoadSession(this._repository);

  @override
  Future<Result<AuthSession?>> call(NoParams params) =>
      _repository.loadSession();
}
