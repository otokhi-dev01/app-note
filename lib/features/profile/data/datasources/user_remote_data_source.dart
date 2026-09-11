import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;

import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';

/// Raw `/api/users` transport backing the Profile feature.
///
/// `AppConstants.userUpdateProfileEndpoint` (`/update-profile`) was tried
/// directly against the live server and returns 404 — that route doesn't
/// exist. `GET /api/users/profile` only accepts GET (confirmed via its
/// `Allow` header on a 405). So there is currently no known way to update a
/// name or fetch-and-persist a profile change through this backend; only the
/// read is wired up here, ready for whenever the real write endpoint is
/// confirmed.
class UserRemoteDataSource extends GetxService {
  final ApiClient _api;

  UserRemoteDataSource({ApiClient? api}) : _api = api ?? Get.find<ApiClient>();

  /// Fetches the signed-in user's profile as the server currently has it.
  ///
  /// Unlike the `/api/auth/*` responses, this endpoint returns the user
  /// object directly at the top level — no `{ code, message, data }`
  /// envelope, and no 'code'/'success' fields (confirmed live: a plain
  /// `{userId, username, displayName, avatarUrl, bio, lastSeenAt, isOnline}`
  /// object). Still checks for a nested `data` key defensively in case that
  /// ever changes to match the auth envelope.
  Future<UserData> fetchProfile() async {
    try {
      final response = await _api.dio.get(
        '${AppConstants.userApiUrl}${AppConstants.userProfileEndpoint}',
      );
      final Map<String, dynamic> json = Map<String, dynamic>.from(
        response.data is Map ? response.data as Map : {},
      );
      final dynamic dataRaw = json['data'] ?? json['Data'];
      final Map<String, dynamic> user = dataRaw is Map
          ? Map<String, dynamic>.from(dataRaw)
          : json;
      return UserData.fromJson(user);
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  Future<String?> uploadProfileImage(String filePath) async {
    try {
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(filePath, filename: 'profile.jpg'),
      });

      final response = await _api.dio.post(
        AppConstants.userUploadProfileEndpoint,
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['imageUrl'] as String?;
      }
    } on dio.DioException catch (e) {
      print('❌ Upload failed: ${e.message}');
    }
    return null;
  }

  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _api.dio.post(
        AppConstants.userUpdateProfileEndpoint,
        data: profileData,
      );
      if (response.statusCode == 200) {
        return true;
      }
    } on dio.DioException catch (e) {
      print('❌ Update failed: ${e.message}');
    }
    return false;
  }
}
