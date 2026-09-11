import 'package:Note/core/error/result.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';

/// Reads and updates the signed-in user's profile.
///
/// [updateName] now round-trips through the `/api/users/update-profile`
/// endpoint. [updateProfileImage] still persists locally only — the backend
/// has an upload endpoint, but wiring it changes how the avatar is stored and
/// resolved app-wide, so that swap is deliberately left for a follow-up.
abstract class ProfileRepository {
  AuthUser? get currentUser;

  Future<Result<AuthUser>> updateName(String fullName);

  Future<Result<AuthUser>> updateProfileImage(String imagePath);
}
