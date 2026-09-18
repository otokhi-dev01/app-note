import 'package:Note/core/error/guard.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/features/profile/data/datasources/identity_remote_data_source.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/entities/identity_document.dart';
import 'package:Note/features/profile/domain/repositories/identity_repository.dart';

class IdentityRepositoryImpl implements IdentityRepository {
  final IdentityRemoteDataSource _remote;

  const IdentityRepositoryImpl(this._remote);

  @override
  Future<Result<void>> uploadDocument(IdentityDocument document) =>
      guard(() => _remote.uploadDocument(document));

  @override
  Future<Result<NationalIdCard>> scanNationalId({
    required String frontImagePath,
    required String backImagePath,
  }) => guard(
    () => _remote.scanNationalId(
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
    ),
  );
}
