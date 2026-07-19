import 'dart:convert';
import '../../domain/entities/note_entity.dart';

class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.folderId,
    required super.title,
    required super.content,
    required super.isPinned,
    required super.isArchived,
    required super.isLocked,
  });

  factory NoteModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return NoteModel(
      id: _toInt(
        json['NoteId'] ??
            json['noteId'] ??
            json['Id'] ??
            json['id'],
      ),
      folderId: _toInt(
        json['FolderId'] ??
            json['folderId'],
      ),
      title: _toString(
        json['Title'] ??
            json['title'],
      ),
      content: _parseContent(json),
      isPinned: _toBool(
        json['IsPinned'] ??
            json['isPinned'],
      ),
      isArchived: _toBool(
        json['IsArchived'] ??
            json['isArchived'],
      ),
      isLocked: _toBool(
        json['IsLocked'] ??
            json['isLocked'],
      ),
    );
  }

  static List<Map<String, dynamic>> _parseContent(
      Map<String, dynamic> json,
      ) {
    dynamic value =
        json['Content'] ??
            json['content'];

    if (value is String &&
        value.trim().isNotEmpty) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        value = null;
      }
    }

    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
        Map<String, dynamic>.from(item),
      )
          .toList();
    }

    final String preview = _toString(
      json['PreviewText'] ??
          json['previewText'] ??
          json['PlainText'] ??
          json['plainText'],
    );

    if (preview.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    return [
      {
        'id': 'preview',
        'type': 'text',
        'text': preview,
      },
    ];
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized =
        value?.toString().toLowerCase() ?? '';

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes';
  }
}