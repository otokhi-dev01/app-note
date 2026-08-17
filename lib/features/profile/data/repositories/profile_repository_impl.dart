import 'package:Note/core/error/guard.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/domain/entities/auth_session.dart';
import 'package:Note/features/profile/domain/repositories/profile_repository.dart';

/// Profile edits are local-only today: there is no server route for them, so
/// the change is written back into the persisted session.
class ProfileRepositoryImpl implements ProfileRepository {
  final SessionStorage _session;

  const ProfileRepositoryImpl(this._session);

  @override
  AuthUser? get currentUser => _session.user.value;

  @override
  Future<Result<AuthUser>> updateName(String fullName) =>
      _patch((user) => user.copyWith(fullName: fullName));

  @override
  Future<Result<AuthUser>> updateProfileImage(String imagePath) =>
      _patch((user) => user.copyWith(profileImage: imagePath));

  Future<Result<AuthUser>> _patch(UserData Function(UserData) change) =>
      guard(() async {
        final current = _session.user.value ?? const UserData();
        final updated = change(current);
        await _session.saveSession(_session.token.value ?? '', updated);
        return updated;
      });
}
