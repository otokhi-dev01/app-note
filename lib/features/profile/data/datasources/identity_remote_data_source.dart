import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;
import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/entities/identity_document.dart';

/// Document uploads use the confirmed `/upload-document` contract.
/// The separate scan/OCR request below still uses a proposed contract.
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
  IdentityRemoteDataSource({ApiClient? api})
    : _api = api ?? Get.find<ApiClient>();

  /// Authenticated document storage, separate from OCR. Contract confirmed
  /// against Chat Swagger; a successful upload does not verify identity.
  Future<void> uploadDocument(IdentityDocument document) async {
    if (!Get.find<SessionStorage>().isLoggedIn) {
      throw const UnauthorizedException('Please sign in to upload a document.');
    }
    try {
      final fields = <String, dynamic>{
        'DocumentType': document.documentType.trim(),
        'DocumentNumber': document.documentNumber.trim(),
      };
      void text(String key, String value) {
        if (value.trim().isNotEmpty) fields[key] = value.trim();
      }

      void date(String key, DateTime? value) {
        if (value != null) {
          fields[key] = DateTime(
            value.year,
            value.month,
            value.day,
          ).toIso8601String();
        }
      }

      text('FullName', document.fullName);
      text('Gender', document.gender);
      text('Nationality', document.nationality);
      text('IssuingCountry', document.issuingCountry);
      text('IssuingAuthority', document.issuingAuthority);
      date('DateOfBirth', document.dateOfBirth);
      date('IssuedDate', document.issuedDate);
      date('ExpiryDate', document.expiryDate);
      for (final entry in {
        'FrontImage': document.frontImagePath,
        'BackImage': document.backImagePath,
      }.entries) {
        final path = entry.value;
        if (path == null || path.isEmpty) continue;
        final filename = Uri.file(path).pathSegments.last;
        final contentType = switch (filename.split('.').last.toLowerCase()) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'heic' => 'image/heic',
          'heif' => 'image/heif',
          'webp' => 'image/webp',
          _ => 'application/octet-stream',
        };
        fields[entry.key] = await dio.MultipartFile.fromFile(
          path,
          filename: filename,
          contentType: dio.DioMediaType.parse(contentType),
        );
      }
      final response = await _api.dio.post(
        '${AppConstants.baseUrl}${AppConstants.uploadDocumentEndpoint}',
        data: dio.FormData.fromMap(fields),
      );
      final body = response.data;
      if (body is! Map || (body['success'] ?? body['Success']) != true) {
        throw ServerException(
          ApiErrorParser.messageFrom(
            body,
            fallback:
                'The document upload was not confirmed. Please try again.',
          ),
        );
      }
    } on FileSystemException {
      throw const ServerException(
        'A selected image could not be read. Please select it again.',
      );
    } on dio.DioException catch (error) {
      throw ApiErrorParser.toException(error);
    }
  }

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
