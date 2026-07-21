import 'package:note_app/core/network/api_client.dart';
import 'package:note_app/core/network/api_endpoints.dart';
import 'package:note_app/core/network/api_exception.dart';
import 'package:note_app/feature/folders/data/datasources/api_client_folder_api_gateway.dart';
import 'package:note_app/feature/folders/data/datasources/folder_api_gateway.dart';
import 'package:note_app/feature/folders/data/models/folder_collection_response.dart';
import 'package:note_app/feature/folders/data/parsers/folder_api_response_validator.dart';
import 'package:note_app/feature/folders/data/parsers/folder_response_parser.dart';
import 'package:note_app/feature/folders/domain/entities/folder_entity.dart';
import 'package:note_app/feature/folders/domain/repositories/folder_repository.dart';

class FolderRepositoryImpl implements FolderRepository {
  final FolderApiGateway _apiGateway;
  final FolderResponseParser _responseParser;
  final FolderApiResponseValidator _responseValidator;

  FolderRepositoryImpl({required ApiClient apiClient})
    : _apiGateway = ApiClientFolderApiGateway(apiClient: apiClient),
      _responseParser = const FolderResponseParser(),
      _responseValidator = const FolderApiResponseValidator();

  FolderRepositoryImpl.withGateway({required FolderApiGateway apiGateway})
    : _apiGateway = apiGateway,
      _responseParser = const FolderResponseParser(),
      _responseValidator = const FolderApiResponseValidator();

  @override
  Future<List<FolderEntity>> getFolders() async {
    final dynamic folderResponse = await _apiGateway.get(ApiEndpoints.folders);
    final FolderCollectionResponse response = _responseParser.parseCollection(
      folderResponse,
      endpoint: ApiEndpoints.folders,
    );

    // The folder API returns active folders and recycle-bin folders together
    // in its `folder` and `trash` collections. There is no separate deleted
    // folder endpoint on the deployed API.
    return _deduplicateFolders(response.folders);
  }

  @override
  Future<void> saveFolder({
    required int id,
    required String name,
    required String iconName,
    required String colorValue,
    required int sortOrder,
  }) async {
    if (id < 0) {
      throw const ApiException(message: 'Invalid folder ID.');
    }

    final String cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw const ApiException(message: 'Folder name is required.');
    }

    if (sortOrder < 0) {
      throw const ApiException(
        message: 'Folder sort order cannot be negative.',
      );
    }

    final dynamic response = await _apiGateway.post(
      ApiEndpoints.saveFolder,
      body: <String, dynamic>{
        'id': id,
        'name': cleanName,
        'iconName': iconName.trim().isEmpty ? 'folder' : iconName.trim(),
        'colorValue': colorValue.trim().isEmpty ? '#2196F3' : colorValue.trim(),
        'sortOrder': sortOrder,
      },
    );

    _responseValidator.ensureCommandSucceeded(response);
  }

  @override
  Future<void> deleteOrRestoreFolder({
    required int id,
    required bool isDelete,
  }) async {
    if (id <= 0) {
      throw const ApiException(message: 'Invalid folder ID.');
    }

    final dynamic response = await _apiGateway.post(
      ApiEndpoints.deleteRestoreFolder,
      body: <String, dynamic>{'id': id, 'isDelete': isDelete},
    );

    _responseValidator.ensureCommandSucceeded(response);

    if (!_operationWasIgnored(response, requestedDelete: isDelete)) {
      return;
    }

    // Historical deployments accept one of these aliases instead of
    // `isDelete`. Retry only when the successful response explicitly says the
    // requested transition was ignored, so normal commands are never doubled.
    final dynamic compatibilityResponse = await _apiGateway.post(
      ApiEndpoints.deleteRestoreFolder,
      body: <String, dynamic>{
        'id': id,
        'folderId': id,
        'folder_id': id,
        'isDeleted': isDelete,
        'is_deleted': isDelete,
        'deleted': isDelete,
        'restore': !isDelete,
        'action': isDelete ? 'delete' : 'restore',
      },
    );

    _responseValidator.ensureCommandSucceeded(compatibilityResponse);

    if (_operationWasIgnored(
      compatibilityResponse,
      requestedDelete: isDelete,
    )) {
      final String action = isDelete ? 'delete' : 'restore';
      final String message = _responseValidator.responseMessage(
        compatibilityResponse,
      );

      throw ApiException(
        message: message.isEmpty
            ? 'The server did not $action the folder.'
            : 'The server did not $action the folder: $message',
        responseData: compatibilityResponse,
      );
    }
  }

  bool _operationWasIgnored(dynamic response, {required bool requestedDelete}) {
    final String message = _responseValidator
        .responseMessage(response)
        .toLowerCase();

    if (requestedDelete) {
      return message.contains('already active') ||
          message.contains('already restored');
    }

    return message.contains('already deleted') ||
        message.contains('already in trash') ||
        message.contains('already inactive');
  }

  List<FolderEntity> _deduplicateFolders(Iterable<FolderEntity> folders) {
    final Map<int, FolderEntity> foldersById = <int, FolderEntity>{};

    for (final FolderEntity folder in folders) {
      final FolderEntity? current = foldersById[folder.id];

      if (current == null || folder.isDeleted || !current.isDeleted) {
        foldersById[folder.id] = folder;
      }
    }

    return List<FolderEntity>.unmodifiable(foldersById.values);
  }
}
