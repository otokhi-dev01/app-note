abstract interface class FolderApiGateway {
  Future<dynamic> get(String path);

  Future<dynamic> post(String path, {required Map<String, dynamic> body});
}
