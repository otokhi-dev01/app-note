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
      // CLEAN CONTRACT: Using multiple keys to ensure backend model binding success.
      // This solves the bug where update (ID > 0) was treated as create.
      final payload = {
        "id": folder.id,
        "Id": folder.id,
        "FolderId": folder.id,
        "ParentId": folder.parentId,
        "Name": folder.name,
        "IconName": folder.iconName,
        "ColorValue": folder.colorValue,
        "SortOrder": folder.sortOrder,
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
  /// Fixes 404 by providing all possible ID and Flag variants for the backend DTO.
  Future<void> deleteRestoreFolder(int folderId, bool isDelete) async {
    try {
      debugPrint('[FOLDER DELETE] POST /api/folder/delete-restore FolderId=$folderId IsDelete=$isDelete');
      
      final payload = {
        "id": folderId,
        "Id": folderId,
        "FolderId": folderId, 
        "isDelete": isDelete,
        "IsDelete": isDelete,
      };

      final response = await _api.dio.post(
        "/api/folder/delete-restore",
        data: payload,
      );

      debugPrint('[FOLDER DELETE] Success: ${response.data}');
    } catch (e, s) {
      debugPrint('[FOLDER SERVICE] deleteRestoreFolder Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> deleteFolderPermanently(int folderId) async {
    try {
      await _api.dio.post(
        "/api/folder/permanent-delete",
        data: {
          "id": folderId,
          "Id": folderId,
          "FolderId": folderId
        },
      );
    } catch (e, s) {
      debugPrint('[FOLDER SERVICE] deleteFolderPermanently Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
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
