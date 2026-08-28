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

  static const _appPayloadKey = '_piiNoteBlock';
  static const _appPayloadVersion = 1;

  static NoteBlock fromJson(Map<String, dynamic> json) {
    final type = asString(json['type'] ?? json['Type']).toLowerCase();
    final id = asString(json['id'] ?? json['Id']);

    switch (type) {
      case 'text':
        final rawText = json['text'] ?? json['Text'] ?? json['content'];
        final payload = _appPayload(rawText);
        return TextBlock(
          id: id,
          text: payload?['text'] is String
              ? payload!['text'] as String
              : _textContent(rawText),
          style: asString(
            payload?['style'] ?? json['style'] ?? json['Style'] ?? 'body',
          ),
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
        final rawText = json['text'] ?? json['Text'];
        final payload = _appPayload(rawText);
        final raw = json['rows'] ?? json['Rows'] ?? payload?['rows'];
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
        final payload = _appPayload(json['text'] ?? json['Text']);
        return DrawingBlock(
          id: id,
          localPath: asString(json['localPath'] ?? payload?['localPath']),
          url: asString(json['url'] ?? json['Url'] ?? payload?['url']),
        );
      default:
        return TextBlock(id: id, text: 'Unknown block type: $type');
    }
  }

  /// Produces exactly the fields accepted by `NoteContentBlockRequest`.
  ///
  /// The logged-in API rejects unmapped JSON properties. App-only values are
  /// therefore encoded inside its nullable `text` field instead of being sent
  /// as unsupported top-level keys. Guest storage uses the same mapper, so the
  /// matching decoder above keeps those richer blocks round-trippable too.
  static Map<String, dynamic> toJson(NoteBlock block) => switch (block) {
    TextBlock(:final id, :final text, :final style) => {
      'id': id,
      'type': 'text',
      'text': style == 'body'
          ? text
          : _encodeAppPayload({'text': text, 'style': style}),
    },
    ChecklistBlock(:final id, :final items) => {
      'id': id,
      'type': 'checklist',
      'items': [
        for (final i in items)
          {'id': i.id, 'text': i.text, 'checked': i.checked},
      ],
    },
    AttachmentBlock(:final id, :final attachmentId, :final displayName) => {
      'id': id,
      'type': 'attachment',
      'attachmentId': attachmentId,
      'displayName': displayName,
    },
    TableBlock(:final id, :final rows) => {
      'id': id,
      'type': 'table',
      'text': _encodeAppPayload({'rows': rows}),
    },
    DrawingBlock(:final id, :final localPath, :final url) => {
      'id': id,
      'type': 'drawing',
      'text': _encodeAppPayload({'localPath': ?localPath, 'url': ?url}),
    },
  };

  static String _encodeAppPayload(Map<String, dynamic> values) =>
      jsonEncode({_appPayloadKey: _appPayloadVersion, ...values});

  static Map<String, dynamic>? _appPayload(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map || decoded[_appPayloadKey] != _appPayloadVersion) {
        return null;
      }
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Quill stores its document as a delta list; keep it encoded as a string so
  /// a text block round-trips whether the server sends plain text or a delta.
  static String _textContent(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List || value is Map) return jsonEncode(value);
    return value.toString();
  }
}
