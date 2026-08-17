import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/guard.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/core/utils/json_parsers.dart';
import 'package:Note/features/folder/data/datasources/folder_remote_data_source.dart';
import 'package:Note/features/folder/data/models/folder_model.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';

class FolderRepositoryImpl implements FolderRepository {
  final FolderRemoteDataSource _remote;

  const FolderRepositoryImpl(this._remote);

  @override
  Future<Result<FolderBundle>> getFolders() => guard(() async {
    final response = await _remote.getFolders();
    return FolderBundle(folders: response.folders, trash: response.trash);
  });

  /// `/api/folder/save` answers 200 even for validation errors, signalling the
  /// real outcome in the body — so the envelope is inspected here rather than
  /// left for the controller to interpret.
  @override
  Future<Result<int>> saveFolder({
    required int id,
    required String name,
    required String iconName,
    required String colorValue,
    int sortOrder = 0,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Folder name cannot be empty.'));
    }

    return guard(() async {
      final body = await _remote.saveFolder(
        FolderModel(
          id: id,
          name: trimmed,
          iconName: iconName,
          colorValue: colorValue,
          sortOrder: sortOrder,
        ),
      );

      final code = asInt(body['code']);
      final succeeded = code == 200 || code == 201 || body['data'] != null;
      if (!succeeded) {
        throw ServerException(ApiErrorParser.messageFrom(body));
      }

      final data = body['data'];
      final savedId = data is Map
          ? asInt(data['FolderId'] ?? data['folderId'] ?? data['id'])
          : 0;
      return savedId > 0 ? savedId : id;
    });
  }

  @override
  Future<Result<void>> deleteRestoreFolder(int folderId, bool isDelete) =>
      guard(() => _remote.deleteRestoreFolder(folderId, isDelete));

  @override
  Future<Result<void>> deleteFolderPermanently(int folderId) =>
      guard(() => _remote.deleteFolderPermanently(folderId));
}
