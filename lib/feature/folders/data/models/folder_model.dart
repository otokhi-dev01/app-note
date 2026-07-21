import '../../domain/entities/folder_entity.dart';

class FolderModel extends FolderEntity {
  const FolderModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.iconName,
    required super.colorValue,
    required super.sortOrder,
    required super.noteCount,
    required super.isInTrash,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: _toInt(
        _readValue(json, const <String>[
          'FolderId',
          'folderId',
          'folder_id',
          'Id',
          'id',
        ]),
      ),
      userId:
          _readValue(json, const <String>[
            'UserId',
            'userId',
            'user_id',
          ])?.toString() ??
          '',
      name:
          _readValue(json, const <String>[
            'FolderName',
            'folderName',
            'folder_name',
            'Name',
            'name',
          ])?.toString() ??
          '',
      iconName:
          _readValue(json, const <String>[
            'IconName',
            'iconName',
            'icon_name',
          ])?.toString() ??
          'folder',
      colorValue:
          _readValue(json, const <String>[
            'ColorValue',
            'colorValue',
            'color_value',
          ])?.toString() ??
          '#2196F3',
      sortOrder: _toInt(
        _readValue(json, const <String>[
          'SortOrder',
          'sortOrder',
          'sort_order',
        ]),
      ),
      noteCount: _toInt(
        _readValue(json, const <String>[
          'NoteCount',
          'noteCount',
          'note_count',
        ]),
      ),
      isInTrash:
          _toBool(
            _readValue(json, const <String>[
              'IsInTrash',
              'isInTrash',
              'is_in_trash',
              'InTrash',
              'inTrash',
              'in_trash',
            ]),
          ) ||
          _toBool(
            _readValue(json, const <String>[
              'IsDeleted',
              'isDeleted',
              'is_deleted',
              'Deleted',
              'deleted',
            ]),
          ) ||
          _isDeletedStatus(
            _readValue(json, const <String>['Status', 'status', 'state']),
          ),
      createdAt: _toDateTime(
        _readValue(json, const <String>[
          'CreatedAt',
          'createdAt',
          'created_at',
        ]),
      ),
      updatedAt: _toDateTime(
        _readValue(json, const <String>[
          'UpdatedAt',
          'updatedAt',
          'updated_at',
        ]),
      ),
      deletedAt: _toDateTime(
        _readValue(json, const <String>[
          'DeletedAt',
          'deletedAt',
          'deleted_at',
          'TrashedAt',
          'trashedAt',
          'trashed_at',
        ]),
      ),
    );
  }

  static dynamic _readValue(Map<String, dynamic> json, List<String> keys) {
    final Map<String, dynamic> valuesByLowerCaseKey = <String, dynamic>{
      for (final MapEntry<String, dynamic> entry in json.entries)
        entry.key.toLowerCase(): entry.value,
    };

    for (final String key in keys) {
      final String normalizedKey = key.toLowerCase();

      if (valuesByLowerCaseKey.containsKey(normalizedKey)) {
        return valuesByLowerCaseKey[normalizedKey];
      }
    }

    return null;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final String text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }

  static bool _isDeletedStatus(dynamic value) {
    final String text = value?.toString().trim().toLowerCase() ?? '';

    return text == 'deleted' ||
        text == 'trash' ||
        text == 'trashed' ||
        text == 'inactive';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is num) {
      final int timestamp = value.toInt();
      final int milliseconds = timestamp.abs() < 100000000000
          ? timestamp * 1000
          : timestamp;

      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    }

    final String text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
