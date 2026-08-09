import 'package:get/get.dart' hide Response;
import 'api_service.dart';
import '../models/folder_model.dart';

class FolderApi {
  final ApiService _api = Get.find<ApiService>();

  Future<List<FolderModel>> getFolders({bool refresh = false}) async {
    final response = await _api.dio.get('/api/folder');
    if (response.statusCode == 200) {
      final data = response.data;
      final list = (data is Map && data['data'] is List) ? data['data'] : data;
      if (list is List) {
        return list
            .map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  }

  Future<bool> saveFolder(FolderModel folder) async {
    final payload = {
      if (folder.id != 0) 'FolderId': folder.id,
      'FolderName': folder.name,
      'Name': folder.name,
      'IconName': folder.iconName,
      'ColorValue': folder.colorValue,
      'SortOrder': folder.sortOrder,
    };

    final response = await _api.dio.post('/api/folder/save', data: payload);
    return response.statusCode == 200;
  }

  Future<bool> deletedRestoreFolder(int id, bool isDelete) async {
    final response = await _api.dio.post(
      '/api/folder/deleted-restore',
      data: {'FolderId': id, 'isDelete': isDelete},
    );
    return response.statusCode == 200;
  }
}
