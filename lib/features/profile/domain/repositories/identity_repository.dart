import 'package:Note/core/error/result.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';

/// Scans a Cambodian national ID card (front/back photos) and returns the
/// parsed Digital Civic ID (e-KYC) result from the backend.
abstract class IdentityRepository {
  Future<Result<NationalIdCard>> scanNationalId({
    required String frontImagePath,
    required String backImagePath,
  });
}
