import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../models/folder_model.dart';
import 'api_service.dart';

class FolderService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  Future<FolderResponse> getFolders() async {
    try {
      final response = await _api.dio.get("/api/folder");
      return FolderResponse.fromJson(response.data);
    } catch (e, s) {
      debugPrint('[FOLDER SERVICE] getFolders Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> saveFolder(FolderModel folder) async {
    try {
      // Backend expects 'Name' as confirmed by the 400 error response field.
      // Casing: 'FolderId', 'Name', 'IconName', 'ColorValue', 'SortOrder'
      final payload = {
        "FolderId": folder.id,
        "Name": folder.name,
        "IconName": folder.iconName,
        "ColorValue": folder.colorValue,
        "SortOrder": folder.sortOrder,
      };

      debugPrint('[FOLDER SAVE] POST /api/folder/save');
      debugPrint('[FOLDER SAVE] Payload: $payload');

      final response = await _api.dio.post("/api/folder/save", data: payload);

      debugPrint('[FOLDER SAVE] Response: ${response.data}');
      return Map<String, dynamic>.from(response.data);
    } catch (e, s) {
      debugPrint('[FOLDER SERVICE] saveFolder Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> deleteRestoreFolder(int folderId, bool isDelete) async {
    try {
      debugPrint('[FOLDER DELETE] POST /api/folder/delete-restore');
      // Standardized contract for delete-restore
      await _api.dio.post(
        "/api/folder/delete-restore",
        data: {"FolderId": folderId, "IsDelete": isDelete},
      );
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
        data: {"FolderId": folderId},
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

    // If 'data' contains field-specific validation lists
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
