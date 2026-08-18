import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;

import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/network/api_capabilities.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/features/folder/data/models/folder_model.dart';

/// Raw `/api/folder` transport.
///
/// Note the routes and payload casing here are the ones the app has always
/// actually used. A second, unused `FolderApi` used to exist alongside this
/// with `FolderName`/`Name` keys and a `/deleted-restore` route; it was dead
/// code and has been removed.
class FolderRemoteDataSource extends GetxService {
  final ApiClient _api = Get.find<ApiClient>();

  /// `parentFolderId: null` fetches the top-level (root) folders; pass a
  /// folder's id to fetch just its immediate children.
  Future<FolderResponse> getFolders({int? parentFolderId}) async {
    try {
      final response = await _api.dio.get(
        '/api/folder',
        queryParameters: parentFolderId != null
            ? {'parentFolderId': parentFolderId}
            : null,
      );
      final body = response.data;
      if (body is! Map) {
        return const FolderResponse(
          folders: [],
          trash: [],
          code: 0,
          message: '',
        );
      }
      return FolderResponse.fromJson(Map<String, dynamic>.from(body));
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Creates when `folder.id == 0`, updates otherwise.
  ///
  /// Returns the raw envelope because the caller needs the server's validation
  /// message when `code != 200`.
  Future<Map<String, dynamic>> saveFolder(FolderModel folder) async {
    try {
      final response = await _api.dio.post(
        '/api/folder/save',
        data: folder.toJson(),
      );
      final body = response.data;
      if (body is! Map) {
        throw const ServerException('Invalid folder save response.');
      }
      return Map<String, dynamic>.from(body);
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Matches `FolderDeleteOrRestoreRequest`: `{ id, isDelete }`.
  Future<void> deleteRestoreFolder(int folderId, bool isDelete) async {
    try {
      await _api.dio.post(
        '/api/folder/delete-restore',
        data: {'id': folderId, 'isDelete': isDelete},
      );
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Not supported: no `/api/folder/permanent-delete` route exists.
  /// See [ApiCapabilities.permanentDelete].
  Future<void> deleteFolderPermanently(int folderId) async {
    throw const UnsupportedFeatureException(
      'Permanently deleting a folder is not available on the server yet.',
    );
  }
}
