import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:notes/core/constants/api_config.dart';
import 'package:notes/data/services/auth_service.dart';
import 'package:notes/data/services/folder_api_service.dart';
import 'package:notes/data/services/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGetConnect client;
  late FolderApiService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final auth = AuthService(LocalStorage());
    await auth.ready;
    client = _FakeGetConnect();
    service = FolderApiService(
      auth,
      client: client,
      tokenProvider: () => 'folder-test-token',
    );
  });

  test('GET folder maps nested server data and sends bearer token', () async {
    client.nextBody = {
      'data': [
        {
          'folderId': 7,
          'folderName': 'Design Projects',
          'createdAt': '2026-07-16T08:00:00Z',
        },
      ],
    };

    final folders = await service.getFolders();

    expect(client.lastMethod, 'GET');
    expect(client.lastUrl, ApiConfig.foldersUrl);
    expect(client.lastHeaders?['Authorization'], 'Bearer folder-test-token');
    expect(folders.single.id, 7);
    expect(folders.single.name, 'Design Projects');
  });

  test('save and delete-restore use POST folder contracts', () async {
    client.nextBody = {
      'data': {'id': 9, 'name': 'Receipts'},
    };
    final saved = await service.saveFolder(id: 9, name: 'Receipts');

    expect(saved?.id, 9);
    expect(client.lastMethod, 'POST');
    expect(client.lastUrl, ApiConfig.saveFolderUrl);
    expect(client.lastBody['id'], 9);
    expect(client.lastBody['name'], 'Receipts');
    expect(client.lastHeaders?['Authorization'], 'Bearer folder-test-token');

    client.nextBody = {'success': true};
    await service.setFolderDeleted(9, deleted: true);

    expect(client.lastUrl, ApiConfig.deleteRestoreFolderUrl);
    expect(client.lastBody['folderId'], 9);
    expect(client.lastBody['isDeleted'], isTrue);
    expect(client.lastBody['action'], 'delete');
  });
}

class _FakeGetConnect extends GetConnect {
  dynamic nextBody;
  int nextStatusCode = 200;
  String? lastMethod;
  String? lastUrl;
  Map<String, String>? lastHeaders;
  Map<String, dynamic> lastBody = {};

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    lastMethod = 'GET';
    lastUrl = url;
    lastHeaders = headers;
    return Response<T>(statusCode: nextStatusCode, body: nextBody as T?);
  }

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    lastMethod = 'POST';
    lastUrl = url;
    lastHeaders = headers;
    lastBody = Map<String, dynamic>.from(body as Map);
    return Response<T>(statusCode: nextStatusCode, body: nextBody as T?);
  }
}
