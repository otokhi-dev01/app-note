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
    final response = await _api.dio.post("/api/folder/save", data: folder.toJson());
    return response.data;
  }

  Future<void> deleteRestoreFolder(int id, bool isDelete) async {
    await _api.dio.post("/api/folder/delete-restore", data: {
      "FolderId": id,
      "isDelete": isDelete,
    });
  }
}
