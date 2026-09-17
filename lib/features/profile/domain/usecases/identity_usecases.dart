import 'package:Note/core/error/result.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/repositories/identity_repository.dart';

class ScanNationalIdParams {
  const ScanNationalIdParams({
    required this.frontImagePath,
    required this.backImagePath,
  });

  final String frontImagePath;
  final String backImagePath;
}

class ScanNationalId extends UseCase<NationalIdCard, ScanNationalIdParams> {
  final IdentityRepository _repository;

  const ScanNationalId(this._repository);

  @override
  Future<Result<NationalIdCard>> call(ScanNationalIdParams params) =>
      _repository.scanNationalId(
        frontImagePath: params.frontImagePath,
        backImagePath: params.backImagePath,
      );
}
