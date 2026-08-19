import 'dart:convert';

import 'package:Note/core/utils/json_parsers.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

/// JSON ⇄ [NoteBlock] translation.
///
/// Kept out of the entities so the editor works with plain value objects. The
/// backend is inconsistent about key casing (`id` vs `Id`, `text` vs `Text`),
/// which is exactly the kind of detail that belongs in the data layer.
class NoteBlockMapper {
  NoteBlockMapper._();

  static NoteBlock fromJson(Map<String, dynamic> json) {
    final type = asString(json['type'] ?? json['Type']).toLowerCase();
    final id = asString(json['id'] ?? json['Id']);

    switch (type) {
      case 'text':
        return TextBlock(
          id: id,
          text: _textContent(json['text'] ?? json['Text'] ?? json['content']),
          style: asString(json['style'] ?? json['Style'] ?? 'body'),
        );
      case 'checklist':
        final raw = json['items'] ?? json['Items'];
        return ChecklistBlock(
          id: id,
          items: (raw is List ? raw : const [])
              .whereType<Map>()
              .map(
                (e) => ChecklistItem(
                  id: asString(e['id'] ?? e['Id']),
                  text: asString(e['text'] ?? e['Text']),
                  checked: asBool(e['checked'] ?? e['Checked']),
                ),
              )
              .toList(),
        );
      case 'attachment':
        return AttachmentBlock(
          id: asString(json['id'] ?? json['Id'] ?? json['BlockId']),
          attachmentId: asInt(
            json['attachmentId'] ?? json['AttachmentId'] ?? json['id'],
          ),
          displayName: asString(
            json['displayName'] ?? json['DisplayName'] ?? json['Name'],
          ),
          url: asString(json['url'] ?? json['Url'] ?? json['FilePath']),
          localPath: asString(json['localPath']),
        );
      case 'table':
        final raw = json['rows'] ?? json['Rows'];
        return TableBlock(
          id: id,
          rows: (raw is List ? raw : const [])
              .map(
                (r) => (r is List)
                    ? r.map((c) => asString(c)).toList()
                    : <String>[],
              )
              .toList(),
        );
      case 'drawing':
        return DrawingBlock(
          id: id,
          localPath: asString(json['localPath']),
          url: asString(json['url'] ?? json['Url']),
        );
      default:
        return TextBlock(id: id, text: 'Unknown block type: $type');
    }
  }

  static Map<String, dynamic> toJson(NoteBlock block) => switch (block) {
    TextBlock(:final id, :final text, :final style) => {
      'id': id,
      'type': 'text',
      'text': text,
      'style': style,
    },
    ChecklistBlock(:final id, :final items) => {
      'id': id,
      'type': 'checklist',
      'items': [
        for (final i in items)
          {'id': i.id, 'text': i.text, 'checked': i.checked},
      ],
    },
    AttachmentBlock(
      :final id,
      :final attachmentId,
      :final displayName,
      :final url,
    ) =>
      {
        'id': id,
        'type': 'attachment',
        'attachmentId': attachmentId,
        'displayName': displayName,
        'url': ?url,
      },
    TableBlock(:final id, :final rows) => {
      'id': id,
      'type': 'table',
      'rows': rows,
    },
    DrawingBlock(:final id, :final localPath, :final url) => {
      'id': id,
      'type': 'drawing',
      'localPath': localPath,
      'url': url,
    },
  };

  /// Quill stores its document as a delta list; keep it encoded as a string so
  /// a text block round-trips whether the server sends plain text or a delta.
  static String _textContent(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List || value is Map) return jsonEncode(value);
    return value.toString();
  }
}
