import 'package:note_app/core/network/api_client.dart';

import 'folder_api_gateway.dart';

class ApiClientFolderApiGateway implements FolderApiGateway {
  final ApiClient apiClient;

  const ApiClientFolderApiGateway({required this.apiClient});

  @override
  Future<dynamic> get(String path) {
    return apiClient.get(path, requiresAuth: true, useAuthBaseUrl: false);
  }

  @override
  Future<dynamic> post(String path, {required Map<String, dynamic> body}) {
    return apiClient.post(
      path,
      body: body,
      requiresAuth: true,
      useAuthBaseUrl: false,
    );
  }
}
