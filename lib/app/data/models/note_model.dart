import 'dart:convert';
import 'package:flutter/material.dart';

class NoteModel {
  final int id;
  final int folderId;
  final String folderName;
  final String title;
  final List<NoteBlock> content;
  final bool isPinned;
  final bool isArchived;
  final bool isLocked;
  final int sortOrder;
  final int attachmentCount;
  final DateTime? pinnedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  NoteModel({
    required this.id,
    required this.folderId,
    required this.folderName,
    required this.title,
    this.content = const [],
    this.isPinned = false,
    this.isArchived = false,
    this.isLocked = false,
    this.sortOrder = 0,
    this.attachmentCount = 0,
    this.pinnedAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  String get displayTitle => title.isEmpty ? "Untitled Note" : title;

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
      folderName: (json['FolderName'] ?? '').toString().trim(),
      title: (json['Title'] ?? '').toString().trim(),
      content: parsedContent,
      isPinned: json['IsPinned'] ?? json['isPinned'] ?? false,
      isArchived: json['IsArchived'] ?? json['isArchived'] ?? false,
      isLocked: json['IsLocked'] ?? json['isLocked'] ?? false,
      sortOrder: json['SortOrder'] ?? 0,
      attachmentCount: json['AttachmentCount'] ?? json['attachmentCount'] ?? 0,
      pinnedAt: json['PinnedAt'] != null ? DateTime.tryParse(json['PinnedAt']) : null,
      createdAt: json['CreatedAt'] != null ? DateTime.tryParse(json['CreatedAt']) : null,
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.tryParse(json['UpdatedAt']) 
          : (json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null),
      deletedAt: json['DeletedAt'] != null ? DateTime.tryParse(json['DeletedAt']) : null,
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
    "SortOrder": sortOrder,
  };
}

class NoteResponse {
  final int code;
  final String message;
  final NoteData? data;

  NoteResponse({required this.code, required this.message, this.data});

  List<NoteModel> get notes => data?.notes ?? [];
  List<NoteModel> get archive => data?.archive ?? [];

  factory NoteResponse.fromJson(Map<String, dynamic> json) {
    return NoteResponse(
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? NoteData.fromJson(json['data']) : null,
    );
  }
}

class NoteData {
  final List<NoteModel> notes;
  final List<NoteModel> archive;

  NoteData({required this.notes, required this.archive});

  factory NoteData.fromJson(Map<String, dynamic> json) {
    return NoteData(
      notes: (json['note'] as List? ?? []).map((e) => NoteModel.fromJson(e)).toList(),
      archive: (json['archive'] as List? ?? []).map((e) => NoteModel.fromJson(e)).toList(),
    );
  }
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
