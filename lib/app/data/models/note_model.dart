import 'dart:convert';
import 'package:flutter/material.dart';

class NoteModel {
  final int id;
  final int folderId;
  final String title;
  final List<NoteBlock> content;
  final bool isPinned;
  final bool isArchived;
  final bool isLocked;
  final int attachmentCount;
  final DateTime? updatedAt;

  NoteModel({
    required this.id,
    required this.folderId,
    required this.title,
    this.content = const [],
    this.isPinned = false,
    this.isArchived = false,
    this.isLocked = false,
    this.attachmentCount = 0,
    this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    var contentData = json['Content'] ?? json['content'];
    List<NoteBlock> parsedContent = [];
    
    if (contentData is List) {
      parsedContent = contentData.map((e) => NoteBlock.fromJson(e)).toList();
    } else if (contentData is String && contentData.isNotEmpty) {
      try {
        final decoded = jsonDecode(contentData);
        if (decoded is List) {
          parsedContent = decoded.map((e) => NoteBlock.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    return NoteModel(
      id: json['NoteId'] ?? json['id'] ?? 0,
      folderId: json['FolderId'] ?? json['folderId'] ?? 0,
      title: json['Title'] ?? json['title'] ?? '',
      content: parsedContent,
      isPinned: json['IsPinned'] ?? json['isPinned'] ?? false,
      isArchived: json['IsArchived'] ?? json['isArchived'] ?? false,
      isLocked: json['IsLocked'] ?? json['isLocked'] ?? false,
      attachmentCount: json['AttachmentCount'] ?? json['attachmentCount'] ?? 0,
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.tryParse(json['UpdatedAt']) 
          : (json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null),
    );
  }

  Map<String, dynamic> toJson() => {
    "NoteId": id,
    "FolderId": folderId,
    "Title": title,
    "Content": jsonEncode(content.map((e) => e.toJson()).toList()),
    "IsPinned": isPinned,
    "IsArchived": isArchived,
    "IsLocked": isLocked,
  };
}

enum BlockType { text, checklist, attachment, table, drawing }

abstract class NoteBlock {
  final String id;
  final BlockType type;

  NoteBlock({required this.id, required this.type});

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type == 'text') return TextBlock.fromJson(json);
    if (type == 'checklist') return ChecklistBlock.fromJson(json);
    if (type == 'attachment') return AttachmentBlock.fromJson(json);
    if (type == 'table') return TableBlock.fromJson(json);
    if (type == 'drawing') return DrawingBlock.fromJson(json);
    throw Exception('Unknown block type: $type');
  }

  Map<String, dynamic> toJson();
}

class DrawingBlock extends NoteBlock {
  final String? localPath;
  final String? url;

  DrawingBlock({required String id, this.localPath, this.url}) 
      : super(id: id, type: BlockType.drawing);

  factory DrawingBlock.fromJson(Map<String, dynamic> json) {
    return DrawingBlock(
      id: json['id'],
      localPath: json['localPath'],
      url: json['url'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "type": "drawing",
    "localPath": localPath,
    "url": url,
  };
}

class TableBlock extends NoteBlock {
  final List<List<String>> rows;

  TableBlock({required String id, required this.rows}) 
      : super(id: id, type: BlockType.table);

  factory TableBlock.fromJson(Map<String, dynamic> json) {
    return TableBlock(
      id: json['id'],
      rows: (json['rows'] as List? ?? [])
          .map((row) => (row as List).map((cell) => cell.toString()).toList())
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "type": "table",
    "rows": rows,
  };
}

class TextBlock extends NoteBlock {
  final String text;
  final String style; // 'title', 'heading', 'body'

  TextBlock({required String id, required this.text, this.style = 'body'}) 
      : super(id: id, type: BlockType.text);

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(
      id: json['id'], 
      text: json['text'] ?? '',
      style: json['style'] ?? 'body',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "type": "text",
    "text": text,
    "style": style,
  };
}

class ChecklistBlock extends NoteBlock {
  final List<ChecklistItem> items;

  ChecklistBlock({required String id, required this.items}) 
      : super(id: id, type: BlockType.checklist);

  factory ChecklistBlock.fromJson(Map<String, dynamic> json) {
    return ChecklistBlock(
      id: json['id'],
      items: (json['items'] as List? ?? [])
          .map((e) => ChecklistItem.fromJson(e))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "type": "checklist",
    "items": items.map((e) => e.toJson()).toList(),
  };
}

class ChecklistItem {
  final String id;
  final String text;
  final bool checked;

  ChecklistItem({required this.id, required this.text, this.checked = false});

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      text: json['text'] ?? '',
      checked: json['checked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "text": text,
    "checked": checked,
  };
}

class AttachmentBlock extends NoteBlock {
  final int attachmentId;
  final String displayName;
  final String? url;
  final String? localPath;

  AttachmentBlock({
    required String id, 
    required this.attachmentId, 
    required this.displayName,
    this.url,
    this.localPath,
  }) : super(id: id, type: BlockType.attachment);

  factory AttachmentBlock.fromJson(Map<String, dynamic> json) {
    return AttachmentBlock(
      id: json['id'],
      attachmentId: json['attachmentId'],
      displayName: json['displayName'] ?? '',
      url: json['url'],
      localPath: json['localPath'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "type": "attachment",
    "attachmentId": attachmentId,
    "displayName": displayName,
    "url": url,
    "localPath": localPath,
  };
}
