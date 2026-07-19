import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_parser.dart';
import '../../domain/entities/folder_entity.dart';
import '../../domain/repositories/folder_repository_impl.dart';
import '../models/folder_model.dart';


class FolderRepositoryImpl implements FolderRepository {
  final ApiClient apiClient;

  const FolderRepositoryImpl({
    required this.apiClient,
  });

  @override
  Future<List<FolderEntity>> getFolders() async {
    final dynamic response = await apiClient.get(
      ApiEndpoints.folders,
    );

    debugPrint(
      'FOLDER API RESPONSE: $response',
    );

    final List<Map<String, dynamic>> folderJsonList =
    ApiParser.asList(response);

    return folderJsonList
        .map(
          (Map<String, dynamic> json) {
        return FolderModel.fromJson(json);
      },
    )
        .toList();
  }

  @override
  Future<void> saveFolder({
    required int id,
    required String name,
    required String iconName,
    required String colorValue,
    required int sortOrder,
  }) async {
    final Map<String, dynamic> requestBody = {
      'id': id,
      'name': name.trim(),
      'iconName': iconName.trim(),
      'colorValue': colorValue.trim(),
      'sortOrder': sortOrder,
    };

    final dynamic response = await apiClient.post(
      ApiEndpoints.saveFolder,
      body: requestBody,
    );

    debugPrint(
      'SAVE FOLDER API RESPONSE: $response',
    );
  }

  @override
  Future<void> deleteOrRestoreFolder({
    required int id,
    required bool isDelete,
  }) async {
    final Map<String, dynamic> requestBody = {
      'id': id,
      'isDelete': isDelete,
    };

    final dynamic response = await apiClient.post(
      ApiEndpoints.deleteRestoreFolder,
      body: requestBody,
    );

    debugPrint(
      'DELETE OR RESTORE FOLDER RESPONSE: $response',
    );
  }
}