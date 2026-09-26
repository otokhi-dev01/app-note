/// The pieces a note is made of.
///
/// Pure value objects — no Flutter, no JSON. Serialization lives in
/// `data/models/note_block_mapper.dart`, so the editor can manipulate blocks
/// without knowing the wire format.
sealed class NoteBlock {
  final String id;
  final String type;

  const NoteBlock({required this.id, required this.type});
}

class TextBlock extends NoteBlock {
  final String text;
  final String style;

  const TextBlock({required super.id, required this.text, this.style = 'body'})
    : super(type: 'text');
}

class ChecklistBlock extends NoteBlock {
  final List<ChecklistItem> items;

  const ChecklistBlock({required super.id, required this.items})
    : super(type: 'checklist');
}

class ChecklistItem {
  final String id;
  final String text;
  final bool checked;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.checked = false,
  });
}

class AttachmentBlock extends NoteBlock {
  final int attachmentId;
  final String displayName;
  final String? url;
  final String? localPath;

  const AttachmentBlock({
    required super.id,
    this.attachmentId = 0,
    required this.displayName,
    this.url,
    this.localPath,
  }) : super(type: 'attachment');

  AttachmentBlock copyWith({
    String? id,
    int? attachmentId,
    String? displayName,
    String? url,
    String? localPath,
  }) => AttachmentBlock(
    id: id ?? this.id,
    attachmentId: attachmentId ?? this.attachmentId,
    displayName: displayName ?? this.displayName,
    url: url ?? this.url,
    localPath: localPath ?? this.localPath,
  );
}

class TableBlock extends NoteBlock {
  final List<List<String>> rows;

  const TableBlock({required super.id, required this.rows})
    : super(type: 'table');
}

class DrawingBlock extends NoteBlock {
  final String? localPath;
  final String? url;

  const DrawingBlock({required super.id, this.localPath, this.url})
    : super(type: 'drawing');

  DrawingBlock copyWith({
    String? id,
    String? localPath,
    String? url,
  }) => DrawingBlock(
    id: id ?? this.id,
    localPath: localPath ?? this.localPath,
    url: url ?? this.url,
  );
}
