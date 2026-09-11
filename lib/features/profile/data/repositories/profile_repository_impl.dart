import 'package:Note/core/error/guard.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';
import 'package:Note/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SessionStorage _session;

  const ProfileRepositoryImpl(this._session);

  @override
  AuthUser? get currentUser => _session.user.value;

  /// Local-only: `POST /api/users/update-profile` (from
  /// `AppConstants.userUpdateProfileEndpoint`) returns 404 on the live
  /// server — confirmed directly, not assumed. `GET /api/users/profile` is
  /// the only method that route accepts. Calling the real endpoint here
  /// would make every rename fail with an error toast, a regression versus
  /// this local-only behavior. Swap this to use `UserRemoteDataSource` once
  /// the real update mechanism is confirmed with the backend team.
  @override
  Future<Result<AuthUser>> updateName(String fullName) =>
      _patchLocal((user) => user.copyWith(fullName: fullName));

  /// The image-upload endpoint exists server-side, but the avatar is still
  /// stored and resolved as a local file throughout the app (see
  /// `ProfileController._syncApiUser`), so this stays local-only until that's
  /// deliberately rearchitected.
  @override
  Future<Result<AuthUser>> updateProfileImage(String imagePath) =>
      _patchLocal((user) => user.copyWith(profileImage: imagePath));

  Future<Result<AuthUser>> _patchLocal(UserData Function(UserData) change) =>
      guard(() async {
        final current = _session.user.value ?? const UserData();
        final updated = change(current);
        await _session.saveSession(_session.token.value ?? '', updated);
        return updated;
      });
}
