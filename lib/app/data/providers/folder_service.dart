import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../models/folder_model.dart';
import 'api_service.dart';

class FolderService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  Future<FolderResponse> getFolders() async {
    final response = await _api.dio.get("/api/folder");
    return FolderResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> saveFolder(FolderModel folder) async {
    try {
      final response = await _api.dio.post("/api/folder/save", data: folder.toJson());
      
      // Handle both {code: 200, ...} and raw data with HTTP 200
      if (response.data is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
        if (!data.containsKey('code')) {
          data['code'] = response.statusCode;
        }
        return data;
      }
      
      return {'code': response.statusCode, 'message': 'Success'};
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRestoreFolder(int id, bool isDelete) async {
    try {
      if (kDebugMode) debugPrint("[FOLDER DEBUG] deleteRestoreFolder ID: $id, isDelete: $isDelete");

      final response = await _api.dio.post(
        "/api/folder/deleted-restore",
        data: {
          "FolderId": id,
          "id": id,
          "Id": id,
          "isDelete": isDelete,
          "IsDelete": isDelete,
        },
      );

      if (kDebugMode) debugPrint("[FOLDER DEBUG] deleteRestoreFolder RESPONSE: ${response.statusCode}");
    } catch (e) {
      if (kDebugMode) debugPrint("[FOLDER DEBUG] deleteRestoreFolder ERROR: $e");
      rethrow;
    }
  }

  Future<void> deleteFolderPermanently(int id) async {
    try {
      if (kDebugMode) debugPrint("[FOLDER DEBUG] deleteFolderPermanently ID: $id");
      await _api.dio.post("/api/folder/permanent-delete", data: {
        "FolderId": id,
        "id": id,
      });
    } catch (e) {
      if (kDebugMode) debugPrint("[FOLDER DEBUG] deleteFolderPermanently ERROR: $e");
      rethrow;
    }
  }
}
