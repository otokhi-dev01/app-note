import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/core/utils/validators.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';
import 'package:Note/features/auth/domain/entities/security_question.dart';
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
  Future<Result<void>> call(String account) {
    if (account.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Please enter your account.')),
      );
    }
    return _repository.forgotPassword(account.trim());
  }
}

class VerifyPasswordOtp extends UseCase<String, VerifyPasswordOtpParams> {
  final AuthRepository _repository;
  const VerifyPasswordOtp(this._repository);

  @override
  Future<Result<String>> call(VerifyPasswordOtpParams params) async {
    if (params.account.trim().isEmpty || params.otp.trim().isEmpty) {
      return const Err(
        ValidationFailure('Please enter your account and verification code.'),
      );
    }
    return _repository.verifyPasswordOtp(
      params.account.trim(),
      params.otp.trim(),
    );
  }
}

class VerifyPasswordOtpParams {
  final String account;
  final String otp;
  const VerifyPasswordOtpParams({required this.account, required this.otp});
}

class ResetPassword extends UseCase<void, ResetPasswordParams> {
  final AuthRepository _repository;
  const ResetPassword(this._repository);

  @override
  Future<Result<void>> call(ResetPasswordParams params) async {
    if (params.resetToken.trim().isEmpty) {
      return const Err(
        ValidationFailure('Please verify your recovery code again.'),
      );
    }
    final weak = Validators.password(params.newPassword);
    if (weak != null) return Err(ValidationFailure(weak));
    if (params.newPassword != params.confirmPassword) {
      return const Err(ValidationFailure('Passwords do not match.'));
    }
    return _repository.resetPassword(
      resetToken: params.resetToken,
      newPassword: params.newPassword,
      confirmPassword: params.confirmPassword,
    );
  }
}

class GetSecurityQuestions extends UseCase<List<SecurityQuestion>, NoParams> {
  final AuthRepository _repository;
  const GetSecurityQuestions(this._repository);

  @override
  Future<Result<List<SecurityQuestion>>> call(NoParams params) =>
      _repository.getSecurityQuestions();
}

class VerifySecurityAnswers
    extends UseCase<String, VerifySecurityAnswersParams> {
  final AuthRepository _repository;
  const VerifySecurityAnswers(this._repository);

  @override
  Future<Result<String>> call(VerifySecurityAnswersParams params) async {
    if (params.account.trim().isEmpty) {
      return const Err(ValidationFailure('Please enter your account.'));
    }
    if (params.answers.length < 3) {
      return const Err(
        ValidationFailure('Please answer 3 security questions.'),
      );
    }
    if (params.answers.any(
          (answer) =>
              answer.questionId.trim().isEmpty || answer.answer.trim().isEmpty,
        )) {
      return const Err(
        ValidationFailure(
          'Select a question and enter its answer for each row.',
        ),
      );
    }
    if (params.answers.map((answer) => answer.questionId).toSet().length !=
        params.answers.length) {
      return const Err(
        ValidationFailure('Please choose each question only once.'),
      );
    }
    return _repository.verifySecurityAnswers(
      params.account.trim(),
      params.answers,
    );
  }
}

class VerifySecurityAnswersParams {
  final String account;
  final List<SecurityAnswer> answers;
  const VerifySecurityAnswersParams({
    required this.account,
    required this.answers,
  });
}

class ResetPasswordParams {
  final String resetToken;
  final String newPassword;
  final String confirmPassword;
  const ResetPasswordParams({
    required this.resetToken,
    required this.newPassword,
    required this.confirmPassword,
  });
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
