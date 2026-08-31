import 'package:flutter_test/flutter_test.dart';

import 'package:Note/features/note/data/models/note_block_mapper.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

void main() {
  const serverFields = {
    'id',
    'type',
    'text',
    'attachmentId',
    'displayName',
    'items',
  };

  test('serialized note blocks only contain API-supported fields', () {
    final blocks = <NoteBlock>[
      const TextBlock(id: 'text', text: 'Hello', style: 'heading'),
      const ChecklistBlock(
        id: 'checklist',
        items: [ChecklistItem(id: 'item', text: 'Done', checked: true)],
      ),
      const AttachmentBlock(
        id: 'attachment',
        attachmentId: 42,
        displayName: 'photo.jpg',
        url: 'https://example.test/photo.jpg',
        localPath: '/tmp/photo.jpg',
      ),
      const TableBlock(
        id: 'table',
        rows: [
          ['A', 'B'],
        ],
      ),
      const DrawingBlock(
        id: 'drawing',
        localPath: '/tmp/drawing.png',
        url: 'https://example.test/drawing.png',
      ),
    ];

    for (final block in blocks) {
      final json = NoteBlockMapper.toJson(block);
      expect(
        json.keys.every(serverFields.contains),
        isTrue,
        reason: '${block.runtimeType} sent unsupported fields: ${json.keys}',
      );
    }
  });

  test('app-only block data round-trips through supported text field', () {
    const blocks = <NoteBlock>[
      TextBlock(id: 'text', text: '[{"insert":"Title\\n"}]', style: 'title'),
      TableBlock(
        id: 'table',
        rows: [
          ['A', 'B'],
          ['C', 'D'],
        ],
      ),
      DrawingBlock(
        id: 'drawing',
        localPath: '/documents/drawing.png',
        url: 'https://example.test/drawing.png',
      ),
    ];

    final text = NoteBlockMapper.fromJson(NoteBlockMapper.toJson(blocks[0]));
    expect(text, isA<TextBlock>());
    expect((text as TextBlock).text, (blocks[0] as TextBlock).text);
    expect(text.style, 'title');

    final table = NoteBlockMapper.fromJson(NoteBlockMapper.toJson(blocks[1]));
    expect(table, isA<TableBlock>());
    expect((table as TableBlock).rows, (blocks[1] as TableBlock).rows);

    final drawing = NoteBlockMapper.fromJson(NoteBlockMapper.toJson(blocks[2]));
    expect(drawing, isA<DrawingBlock>());
    expect(
      (drawing as DrawingBlock).localPath,
      (blocks[2] as DrawingBlock).localPath,
    );
    expect(drawing.url, (blocks[2] as DrawingBlock).url);
  });

  test('attachment URL is not sent in content payload', () {
    final json = NoteBlockMapper.toJson(
      const AttachmentBlock(
        id: 'attachment',
        attachmentId: 7,
        displayName: 'voice.m4a',
        url: 'https://example.test/voice.m4a',
      ),
    );

    expect(json, {
      'id': 'attachment',
      'type': 'attachment',
      'attachmentId': 7,
      'displayName': 'voice.m4a',
    });
  });
}
