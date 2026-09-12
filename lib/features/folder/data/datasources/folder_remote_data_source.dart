import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;
import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/network/api_capabilities.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/features/folder/data/models/folder_model.dart';

/// Raw `/api/folder` transport.
/// Note the routes and payload casing here are the ones the app has always
/// actually used. A second, unused `FolderApi` used to exist alongside this
/// with `FolderName`/`Name` keys and a `/deleted-restore` route; it was dead
/// code and has been removed.
class FolderRemoteDataSource extends GetxService {
  final ApiClient _api = Get.find<ApiClient>();

  /// `parentFolderId: null` fetches the top-level (root) folders; pass a
  /// folder's id to fetch just its immediate children.
  Future<FolderResponse> getFolders({int? parentFolderId}) =>
      _getFolders(parentFolderId: parentFolderId);

  /// The post-login failure this was chasing: the very first `/api/folder`
  /// call right after login can 401 even though the token the client just
  /// received from the Chat server is provably fresh — `AuthController`
  /// awaits `saveSession` before navigating here, so this isn't a client-side
  /// timing bug. That points to the Note server's own session/token check
  /// lagging behind the Chat server by a beat. One silent retry absorbs that
  /// race; a 401 that survives the retry is treated as a real auth failure.
  Future<FolderResponse> _getFolders({
    int? parentFolderId,
    bool retriedAfterUnauthorized = false,
  }) async {
    try {
      final response = await _api.dio.get(
        '/api/folder',
        queryParameters: parentFolderId != null
            ? {'parentFolderId': parentFolderId}
            : null,
      );
      final body = response.data;
      if (body is! Map) {
        if (body is List) {
          return FolderResponse(
            folders: (body)
                .whereType<Map>()
                .map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
            trash: [],
            code: 200,
            message: 'Success',
          );
        }
        return const FolderResponse(
          folders: [],
          trash: [],
          code: 0,
          message: '',
        );
      }
      return FolderResponse.fromJson(Map<String, dynamic>.from(body));
    } on dio.DioException catch (e) {
      // TEMP DEBUG — remove once the post-login failure is diagnosed.
      // ignore: avoid_print
      print(
        '❌ GET /api/folder failed: type=${e.type} status=${e.response?.statusCode} '
        'body=${e.response?.data ?? e.message} retried=$retriedAfterUnauthorized',
      );
      if (!retriedAfterUnauthorized && e.response?.statusCode == 401) {
        await Future.delayed(const Duration(milliseconds: 700));
        return _getFolders(
          parentFolderId: parentFolderId,
          retriedAfterUnauthorized: true,
        );
      }
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
      // TEMP DEBUG — remove once the real envelope shape is confirmed; this
      // endpoint answers 200 even on failure, so without this the console
      // shows nothing at all when the app misreads a 200 body as a failure.
      // ignore: avoid_print
      print('📤 folder save raw response -> ${response.statusCode}: $body');
      if (body is! Map) {
        throw ServerException('Invalid folder save response: $body');
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
