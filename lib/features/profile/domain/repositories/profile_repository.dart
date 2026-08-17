import 'package:Note/core/error/result.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';

/// Reads and updates the signed-in user's profile.
///
/// The backend has no profile endpoint yet, so the implementation persists to
/// the stored session. Keeping that behind this interface means swapping in a
/// real endpoint later touches only the data layer.
abstract class ProfileRepository {
  AuthUser? get currentUser;

  Future<Result<AuthUser>> updateName(String fullName);

  Future<Result<AuthUser>> updateProfileImage(String imagePath);
}
