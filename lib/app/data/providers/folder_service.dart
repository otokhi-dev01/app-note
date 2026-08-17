import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../models/folder_model.dart';
import 'api_service.dart';

class FolderService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  Future<FolderResponse> getFolders() async {
    try {
      final response = await _api.dio.get("/api/folder");
      if (kDebugMode) debugPrint('[FOLDER LIST] Raw: ${response.data}');
      return FolderResponse.fromJson(response.data);
    } catch (e, s) {
      debugPrint('[FOLDER SERVICE] getFolders Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// Saves or updates a folder.
  /// FolderId: 0 for Create, > 0 for Update.
  Future<Map<String, dynamic>> saveFolder(FolderModel folder) async {
    try {
      // Matches FolderSaveRequest: { id, name*, iconName, colorValue, sortOrder }.
      // id == 0 creates, id > 0 updates.
      // NOTE: the API has no parentId field, so folder nesting is not persisted.
      final payload = {
        "id": folder.id,
        "name": folder.name,
        "iconName": folder.iconName,
        "colorValue": folder.colorValue,
        "sortOrder": folder.sortOrder,
      };

      debugPrint('[FOLDER SAVE] POST /api/folder/save ID=${folder.id}');
      final response = await _api.dio.post("/api/folder/save", data: payload);
      
      debugPrint('[FOLDER SAVE] Response: ${response.data}');
      return Map<String, dynamic>.from(response.data);
    } catch (e, s) {
      debugPrint('[FOLDER SERVICE] saveFolder Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// Toggles folder delete/restore state.
  /// Matches FolderDeleteOrRestoreRequest: { id, isDelete }.
  Future<void> deleteRestoreFolder(int folderId, bool isDelete) async {
    try {
      debugPrint('[FOLDER DELETE] POST /api/folder/delete-restore FolderId=$folderId isDelete=$isDelete');

      final response = await _api.dio.post(
        "/api/folder/delete-restore",
        data: {"id": folderId, "isDelete": isDelete},
      );

      debugPrint('[FOLDER DELETE] Success: ${response.data}');
    } catch (e, s) {
      debugPrint('[FOLDER SERVICE] deleteRestoreFolder Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// Not supported: the API exposes no /api/folder/permanent-delete route.
  /// See [ApiCapabilities.permanentDelete].
  Future<void> deleteFolderPermanently(int folderId) async {
    throw const ApiUnsupportedException(
      'Permanently deleting a folder is not available on the server yet.',
    );
  }

  /// Extracts a user-friendly error message from the API response
  static String getApiErrorMessage(dynamic responseData) {
    if (responseData is! Map) {
      return 'An unexpected error occurred.';
    }

    final data = responseData['data'];

    if (data is Map) {
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }

    return responseData['message']?.toString() ?? 'Something went wrong.';
  }
}
