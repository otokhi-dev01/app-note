import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;
import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';

/// Raw transport for the Digital Civic ID (national ID) scan/e-KYC flow.
///
/// PROPOSED CONTRACT — `AppConstants.identityApiUrl` / `identityScanEndpoint`
/// have not been confirmed against a live backend (no such route has been
/// verified to exist yet). This posts the front/back card photos as
/// multipart fields named `front`/`back` and expects a JSON body matching
/// `NationalIdCard.fromJson`. Once the backend team confirms the real path,
/// field names, and response shape, update those three places together —
/// see `UserRemoteDataSource`'s doc comment for what happens when a guessed
/// endpoint is wired up unconfirmed (a confirmed 404 in production).
class IdentityRemoteDataSource extends GetxService {
  final ApiClient _api;
  IdentityRemoteDataSource({ApiClient? api}) : _api = api ?? Get.find<ApiClient>();

  /// Uploads the front and back photos of the card and returns the server's
  /// parsed OCR/e-KYC result.
  Future<NationalIdCard> scanNationalId({
    required String frontImagePath,
    required String backImagePath,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'front': await dio.MultipartFile.fromFile(
          frontImagePath,
          filename: 'id_front.jpg',
        ),
        'back': await dio.MultipartFile.fromFile(
          backImagePath,
          filename: 'id_back.jpg',
        ),
      });
      final response = await _api.dio.post(
        '${AppConstants.identityApiUrl}${AppConstants.identityScanEndpoint}',
        data: formData,
      );
      final Map<String, dynamic> json = Map<String, dynamic>.from(
        response.data is Map ? response.data as Map : {},
      );
      // Mirrors UserRemoteDataSource's defensive unwrap: accept either a
      // bare object or one nested under a `data`/`Data` envelope.
      final dynamic dataRaw = json['data'] ?? json['Data'];
      final Map<String, dynamic> result = dataRaw is Map
          ? Map<String, dynamic>.from(dataRaw)
          : json;
      return NationalIdCard.fromJson(
        result,
        frontImagePath: frontImagePath,
        backImagePath: backImagePath,
      );
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }
}
