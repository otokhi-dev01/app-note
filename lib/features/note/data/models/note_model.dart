import 'dart:convert';

import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/core/utils/json_parsers.dart';
import 'package:Note/features/note/data/models/note_block_mapper.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

/// [Note] plus the wire format.
///
/// Every quirk of the backend payload lives here: dual key casing
/// (`NoteId` / `id`), attachments arriving in a sibling array that has to be
/// merged into the content blocks, and relative file paths that need the host
/// prepended.
class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.folderId,
    required super.folderName,
    required super.title,
    super.content,
    super.isPinned,
    super.isArchived,
    super.isLocked,
    super.updatedAt,
    super.deletedAt,
    super.attachmentCount,
    super.isDeleteFlag,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final int id = asInt(json['NoteId'] ?? json['id'] ?? json['Id']);
    final int folderId = asInt(json['FolderId'] ?? json['folderId']);
    final String title = asString(json['Title'] ?? json['title']);
    final String folderName = asString(
      json['FolderName'] ?? json['folderName'],
    );

    // 1. Structured content from ContentJson
    dynamic rawContent =
        json['ContentJson'] ?? json['content'] ?? json['Content'];
    List<NoteBlock> blocks = [];

    if (rawContent != null) {
      if (rawContent is String && rawContent.isNotEmpty) {
        try {
          rawContent = jsonDecode(rawContent);
        } catch (_) {}
      }
      if (rawContent is List) {
        blocks = rawContent
            .map((e) => NoteBlockMapper.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    // 2. Merge the sibling attachment array into the blocks
    final dynamic rawAtts = json['Attachments'] ?? json['attachments'];
    final List rawAttachments = rawAtts is List ? rawAtts : const [];

    for (final att in rawAttachments) {
      if (att is! Map) continue;
      final map = Map<String, dynamic>.from(att);
      final String blockId = asString(map['BlockId'] ?? map['blockId']);
      final String? fullUrl = normalizeAttachmentUrl(
        asString(
          map['FilePath'] ?? map['filePath'] ?? map['Url'] ?? map['url'],
        ),
      );

      final int existingIndex = blockId.isEmpty
          ? -1
          : blocks.indexWhere((b) => b.id == blockId);

      if (existingIndex != -1 && blocks[existingIndex] is AttachmentBlock) {
        // Merge metadata into the block the editor already knows about
        final old = blocks[existingIndex] as AttachmentBlock;
        blocks[existingIndex] = AttachmentBlock(
          id: blockId,
          attachmentId: asInt(
            map['AttachmentId'] ?? map['id'] ?? old.attachmentId,
          ),
          displayName: asString(
            map['OriginalFileName'] ??
                map['fileName'] ??
                map['Name'] ??
                old.displayName,
          ),
          url: fullUrl ?? old.url,
          localPath: old.localPath,
        );
      } else {
        // New block. Without a BlockId the attachment id stands in as the key.
        final attId = asInt(map['AttachmentId'] ?? map['id']);
        blocks.add(
          AttachmentBlock(
            id: blockId.isNotEmpty ? blockId : 'att_$attId',
            attachmentId: attId,
            displayName: asString(
              map['OriginalFileName'] ??
                  map['fileName'] ??
                  map['Name'] ??
                  'Attachment',
            ),
            url: fullUrl,
          ),
        );
      }
    }

    // 3. Fall back to plain text when the note predates structured content
    if (blocks.isEmpty) {
      final String plainText = asString(
        json['Text'] ?? json['text'] ?? json['Body'] ?? json['body'],
      );
      if (plainText.isNotEmpty) {
        blocks.add(TextBlock(id: 'initial', text: plainText));
      }
    }

    return NoteModel(
      id: id,
      folderId: folderId,
      folderName: folderName,
      title: title,
      content: blocks,
      isPinned: asBool(json['IsPinned'] ?? json['isPinned']),
      isArchived: asBool(json['IsArchived'] ?? json['isArchived']),
      isLocked: asBool(json['IsLocked'] ?? json['isLocked']),
      updatedAt: asDate(json['UpdatedAt'] ?? json['updatedAt']),
      deletedAt: asDate(json['DeletedAt'] ?? json['deletedAt']),
      isDeleteFlag: asBool(json['IsDelete'] ?? json['isDelete']),
      attachmentCount: asInt(
        json['AttachmentCount'] ?? json['attachmentCount'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'NoteId': id,
    'FolderId': folderId,
    'Title': title,
    'ContentJson': content.map(NoteBlockMapper.toJson).toList(),
  };
}
