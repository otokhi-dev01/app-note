import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';
import 'package:Note/features/profile/domain/repositories/profile_repository.dart';

class UpdateUserName extends UseCase<AuthUser, String> {
  final ProfileRepository _repository;

  const UpdateUserName(this._repository);

  @override
  Future<Result<AuthUser>> call(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Please enter your name.')),
      );
    }
    return _repository.updateName(trimmed);
  }
}

class UpdateProfileImage extends UseCase<AuthUser, String> {
  final ProfileRepository _repository;

  const UpdateProfileImage(this._repository);

  @override
  Future<Result<AuthUser>> call(String imagePath) =>
      _repository.updateProfileImage(imagePath);
}
