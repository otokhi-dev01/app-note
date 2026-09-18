import 'package:Note/core/error/result.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/entities/identity_document.dart';
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

class UploadIdentityDocument extends UseCase<void, IdentityDocument> {
  final IdentityRepository _repository;
  const UploadIdentityDocument(this._repository);

  @override
  Future<Result<void>> call(IdentityDocument document) async {
    if (document.documentType.trim().isEmpty ||
        document.documentNumber.trim().isEmpty) {
      return const Err(
        ValidationFailure('Document type and document number are required.'),
      );
    }
    if (document.issuedDate != null &&
        document.expiryDate != null &&
        document.expiryDate!.isBefore(document.issuedDate!)) {
      return const Err(
        ValidationFailure('Expiry date must not be before the issue date.'),
      );
    }
    return _repository.uploadDocument(document);
  }
}
