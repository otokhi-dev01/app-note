import 'dart:convert';

import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

/// The one-line preview under a note's title.
///
/// Replaces four `_getContentSnippet` copies that disagreed about the empty
/// case — one said `"Attachments"`, another `"3 attachments"`, a third `""`.
class NoteSnippet {
  NoteSnippet._();

  static String of(Note note) {
    final firstText = note.content.whereType<TextBlock>().firstOrNull;
    if (firstText != null) {
      final text = plainText(firstText.text);
      if (text.isNotEmpty) return text;
    }

    if (note.attachmentCount > 0) return _attachmentLabel(note.attachmentCount);

    final attachments = note.content.whereType<AttachmentBlock>().length;
    if (attachments > 0) return _attachmentLabel(attachments);

    if (note.content.any((b) => b is ChecklistBlock)) return 'Checklist';
    if (note.content.any((b) => b is DrawingBlock)) return 'Drawing';
    if (note.content.any((b) => b is TableBlock)) return 'Table';

    return 'No additional text';
  }

  /// A multi-line preview for the grid card, which shows a paragraph rather
  /// than the single line [of] returns.
  static String preview(Note note, {int maxParts = 6}) {
    if (note.content.isEmpty) return '';

    final parts = <String>[];
    for (final block in note.content) {
      switch (block) {
        case TextBlock(:final text):
          final flat = plainText(text);
          if (flat.isNotEmpty) parts.add(flat);
        case ChecklistBlock(:final items):
          for (final item in items) {
            if (item.text.isNotEmpty) parts.add('• ${item.text}');
          }
        case TableBlock():
          parts.add('[Table Content]');
        case AttachmentBlock() || DrawingBlock():
          break;
      }
      if (parts.length > maxParts) break;
    }

    return parts.join('\n');
  }

  /// Flattens whatever a text block holds into readable text.
  ///
  /// The editor stores Quill deltas, so the value can be a JSON string, a
  /// decoded delta list, or plain text depending on where the note came from.
  static String plainText(dynamic value) {
    if (value == null) return '';

    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => item['insert']?.toString() ?? '')
          .join()
          .trim();
    }

    if (value is String) {
      final text = value.trim();
      if (text.startsWith('[') || text.startsWith('{')) {
        try {
          return plainText(jsonDecode(text));
        } catch (_) {
          // Not JSON after all — fall through and use it verbatim.
        }
      }
      return text;
    }

    return value.toString();
  }

  static String _attachmentLabel(int count) =>
      '$count attachment${count == 1 ? '' : 's'}';
}
