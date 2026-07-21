import 'package:note_app/core/network/api_exception.dart';

import '../../domain/entities/folder_entity.dart';
import '../models/folder_collection_response.dart';
import '../models/folder_model.dart';
import 'folder_api_response_validator.dart';

class FolderResponseParser {
  final FolderApiResponseValidator _responseValidator;

  const FolderResponseParser({
    FolderApiResponseValidator responseValidator =
        const FolderApiResponseValidator(),
  }) : _responseValidator = responseValidator;

  FolderCollectionResponse parseCollection(
    dynamic response, {
    required String endpoint,
    bool markAllDeleted = false,
  }) {
    _responseValidator.ensureSuccessfulEnvelope(response);

    final ({
      List<dynamic> active,
      List<dynamic> deleted,
      bool includesDeletedCollection,
    })?
    collections = _extractCollections(response, markAllDeleted: markAllDeleted);

    if (collections == null) {
      throw ApiException(
        message: 'The folder response from $endpoint does not contain a list.',
        responseData: response,
      );
    }

    final List<FolderEntity> folders = <FolderEntity>[
      ..._parseItems(
        collections.active,
        endpoint: endpoint,
        markDeleted: markAllDeleted,
      ),
      ..._parseItems(
        collections.deleted,
        endpoint: endpoint,
        markDeleted: true,
      ),
    ];

    return FolderCollectionResponse(
      folders: List<FolderEntity>.unmodifiable(folders),
      includesDeletedCollection:
          markAllDeleted || collections.includesDeletedCollection,
    );
  }

  ({
    List<dynamic> active,
    List<dynamic> deleted,
    bool includesDeletedCollection,
  })?
  _extractCollections(dynamic value, {required bool markAllDeleted}) {
    if (value is List) {
      return (
        active: markAllDeleted ? <dynamic>[] : value,
        deleted: markAllDeleted ? value : <dynamic>[],
        includesDeletedCollection: markAllDeleted,
      );
    }

    if (value is! Map) {
      return null;
    }

    final Map<String, dynamic> map = _convertMap(value);

    const List<String> activeKeys = <String>[
      'folder',
      'folders',
      'items',
      'rows',
      'records',
      'results',
      'list',
      'content',
    ];
    const List<String> deletedKeys = <String>[
      'trash',
      'trashFolders',
      'trash_folders',
      'deleted',
      'deletedFolders',
      'deleted_folders',
    ];

    final bool hasActive = _containsKey(map, activeKeys);
    final bool hasDeleted = _containsKey(map, deletedKeys);

    if (hasActive || hasDeleted) {
      final List<dynamic> active = _readCollection(
        map,
        activeKeys,
        collectionName: 'folder',
      );
      final List<dynamic> deleted = _readCollection(
        map,
        deletedKeys,
        collectionName: 'deleted folder',
      );

      if (markAllDeleted) {
        return (
          active: <dynamic>[],
          deleted: <dynamic>[...active, ...deleted],
          includesDeletedCollection: true,
        );
      }

      return (
        active: active,
        deleted: deleted,
        includesDeletedCollection: hasDeleted,
      );
    }

    for (final String wrapperKey in const <String>[
      'data',
      'result',
      'payload',
    ]) {
      if (!_containsKey(map, <String>[wrapperKey])) {
        continue;
      }

      return _extractCollections(
        _readValue(map, <String>[wrapperKey]),
        markAllDeleted: markAllDeleted,
      );
    }

    return null;
  }

  List<dynamic> _readCollection(
    Map<String, dynamic> map,
    List<String> keys, {
    required String collectionName,
  }) {
    if (!_containsKey(map, keys)) {
      return <dynamic>[];
    }

    final dynamic value = _readValue(map, keys);

    // Some APIs encode an empty database result as null.
    if (value == null) {
      return <dynamic>[];
    }

    if (value is List) {
      return value;
    }

    throw ApiException(
      message: 'The $collectionName collection is not a list.',
      responseData: map,
    );
  }

  List<FolderEntity> _parseItems(
    List<dynamic> items, {
    required String endpoint,
    required bool markDeleted,
  }) {
    return List<FolderEntity>.generate(items.length, (int index) {
      final dynamic item = items[index];

      if (item is! Map) {
        throw ApiException(
          message: 'Folder item ${index + 1} from $endpoint is not an object.',
          responseData: item,
        );
      }

      final FolderModel folder = FolderModel.fromJson(_convertMap(item));

      if (folder.id <= 0) {
        throw ApiException(
          message: 'Folder item ${index + 1} from $endpoint has no valid ID.',
          responseData: item,
        );
      }

      if (markDeleted && !folder.isDeleted) {
        return folder.copyWith(isInTrash: true);
      }

      return folder;
    }, growable: false);
  }

  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> map) {
    return map.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }

  bool _containsKey(Map<String, dynamic> map, Iterable<String> keys) {
    final Set<String> normalizedKeys = keys
        .map((String key) => key.toLowerCase())
        .toSet();

    return map.keys.any(
      (String key) => normalizedKeys.contains(key.toLowerCase()),
    );
  }

  dynamic _readValue(Map<String, dynamic> map, Iterable<String> keys) {
    final Map<String, dynamic> normalizedMap = <String, dynamic>{
      for (final MapEntry<String, dynamic> entry in map.entries)
        entry.key.toLowerCase(): entry.value,
    };

    for (final String key in keys) {
      final String normalizedKey = key.toLowerCase();

      if (normalizedMap.containsKey(normalizedKey)) {
        return normalizedMap[normalizedKey];
      }
    }

    return null;
  }
}
