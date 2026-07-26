import 'package:dio/dio.dart' as dio;
import '../models/folder_model.dart';
import '../providers/api_provider.dart';

class FolderRepository extends ApiProvider {
  Future<List<FolderModel>> getFolders() async {
    final response = await get('/folder');
    if (response.statusCode == 200) {
      final rawData = response.data['data'];
      if (rawData is List) {
        return rawData.map((e) => FolderModel.fromJson(e)).toList();
      } else if (rawData is Map && rawData.containsKey('folder')) {
        final List folders = rawData['folder'] ?? [];
        return folders.map((e) => FolderModel.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<dio.Response> saveFolder(FolderModel folder) async {
    return await post('/folder/save', data: folder.toJson());
  }

  Future<dio.Response> deleteRestoreFolder(int id, bool isDelete) async {
    return await post('/folder/delete-restore', data: {
      'id': id,
      'isDelete': isDelete,
    });
  }
}
