import 'package:Note/features/note/domain/entities/note_block.dart';

/// A note as the app reasons about it — no JSON, no Flutter.
///
/// `NoteModel` in the data layer extends this and adds the wire format.
class Note {
  final int id;
  final int folderId;
  final String folderName;
  final String title;
  final List<NoteBlock> content;
  final bool isPinned;
  final bool isArchived;
  final bool isLocked;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int attachmentCount;

  /// Some list endpoints report deletion with a flag instead of a timestamp.
  final bool isDeleteFlag;

  const Note({
    required this.id,
    required this.folderId,
    required this.folderName,
    required this.title,
    this.content = const [],
    this.isPinned = false,
    this.isArchived = false,
    this.isLocked = false,
    this.updatedAt,
    this.deletedAt,
    this.attachmentCount = 0,
    this.isDeleteFlag = false,
  });

  String get displayTitle => title.isEmpty ? 'Untitled Note' : title;

  bool get isDeleted => deletedAt != null || isDeleteFlag;

  /// True when the note has no blocks and no attachments.
  bool get isEmpty => content.isEmpty && attachmentCount == 0;
}
