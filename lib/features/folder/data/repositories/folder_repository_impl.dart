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

  /// `parentFolderId: null` now only returns the root level, so a full tree
  /// takes one call per folder that reports `hasChildren` — walked here so
  /// every existing caller still gets the complete flat set it always did.
  @override
  Future<Result<FolderBundle>> getFolders() => guard(() async {
    final folders = <FolderModel>[];
    final trashById = <int, FolderModel>{};
    final visited = <int>{};

    Future<void> collect(int? parentId) async {
      final response = await _remote.getFolders(parentFolderId: parentId);
      folders.addAll(response.folders);
      for (final f in response.trash) {
        trashById[f.id] = f;
      }
      for (final f in response.folders) {
        if (f.hasChildren && visited.add(f.id)) {
          await collect(f.id);
        }
      }
    }

    await collect(null);
    return FolderBundle(folders: folders, trash: trashById.values.toList());
  });

  /// `/api/folder/save` answers 200 even for validation errors, signalling the
  /// real outcome in the body — so the envelope is inspected here rather than
  /// left for the controller to interpret.
  @override
  Future<Result<int>> saveFolder({
    required int id,
    int? parentId,
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
          parentId: parentId,
          name: trimmed,
          iconName: iconName,
          colorValue: colorValue,
          sortOrder: sortOrder,
        ),
      );

      _throwIfSaveFailed(body);

      int savedId = _savedFolderId(body);
      if (savedId == 0 && id == 0) {
        try {
          final response = await _remote.getFolders();
          final match = response.folders
              .where((f) => f.name == trimmed)
              .toList()
            ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          if (match.isNotEmpty) {
            savedId = match.first.id;
          }
        } catch (_) {
          // Ignore fetch error
        }
      }

      return savedId > 0 ? savedId : id;
    });
  }

  static int _savedFolderId(Object? value) {
    if (value is Map) {
      final id = asInt(
        value['FolderId'] ?? value['folderId'] ?? value['id'] ?? value['Id'],
      );
      if (id > 0) return id;
      for (final key in ['data', 'Data', 'folder', 'Folder', 'result', 'Result']) {
        final nestedId = _savedFolderId(value[key]);
        if (nestedId > 0) return nestedId;
      }
      return 0;
    }
    if (value is List) {
      return value.length == 1 ? _savedFolderId(value.single) : 0;
    }
    return value is int || value is String ? asInt(value) : 0;
  }

  static void _throwIfSaveFailed(Object? body) {
    if (body is! Map) return;
    final rawCode =
        body['code'] ??
        body['Code'] ??
        body['statusCode'] ??
        body['StatusCode'];
    final code = rawCode == null ? null : asInt(rawCode);
    final success = body['success'] ?? body['Success'];
    if ((success != null && !asBool(success)) ||
        (code != null && (code < 200 || code >= 300))) {
      throw ServerException(ApiErrorParser.messageFrom(body), statusCode: code);
    }
  }

  @override
  Future<Result<void>> deleteRestoreFolder(int folderId, bool isDelete) =>
      guard(() => _remote.deleteRestoreFolder(folderId, isDelete));

  @override
  Future<Result<void>> deleteFolderPermanently(int folderId) =>
      guard(() => _remote.deleteFolderPermanently(folderId));
}
