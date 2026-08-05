import 'dart:convert';
import 'package:flutter/foundation.dart';

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
    const String baseUrl = "https://note.piisiit.com";
    
    // 1. Parse Content (Text, Checklists, etc.)
    var contentData = json['ContentJson'] ?? json['Content'] ?? json['content'] ?? json['NoteContent'] ?? json['blocks'] ?? json['data'];
    List<NoteBlock> parsedContent = [];
    
    if (contentData is List) {
      parsedContent = contentData.map((e) => NoteBlock.fromJson(Map<String, dynamic>.from(e))).toList();
    } else if (contentData is String && contentData.isNotEmpty) {
      try {
        final decoded = jsonDecode(contentData);
        if (decoded is List) {
          parsedContent = decoded.map((e) => NoteBlock.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      } catch (_) {
        if (kDebugMode) debugPrint("Failed to decode Content string: $contentData");
      }
    }

    // 2. Parse Attachments (Images/Videos)
    final List rawAttachments = (json['Attachments'] ?? json['attachments'] ?? []) as List;
    for (var att in rawAttachments) {
      final map = Map<String, dynamic>.from(att);
      final String blockId = (map['BlockId'] ?? map['blockId'] ?? '').toString();
      
      // Check if this attachment is already represented in content blocks
      bool alreadyInContent = parsedContent.any((b) => b.id == blockId);
      
      if (!alreadyInContent) {
        String? relativePath = map['FilePath'] ?? map['filePath'] ?? map['Url'] ?? map['url'];
        String? fullUrl;
        if (relativePath != null) {
          fullUrl = relativePath.startsWith('http') ? relativePath : "$baseUrl$relativePath";
        }

        parsedContent.add(AttachmentBlock(
          id: blockId.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : blockId,
          attachmentId: map['AttachmentId'] ?? map['id'] ?? 0,
          displayName: map['OriginalFileName'] ?? map['fileName'] ?? 'Attachment',
          url: fullUrl,
          localPath: null,
        ));
      }
    }

    return NoteModel(
      id: json['NoteId'] ?? json['id'] ?? 0, // Fallback to 'id' if 'NoteId' is missing
      folderId: json['FolderId'] ?? json['folderId'] ?? 0,
      folderName: (json['FolderName'] ?? json['folderName'] ?? '').toString().trim(),
      title: (json['Title'] ?? json['title'] ?? '').toString().trim(),
      content: parsedContent,
      isPinned: json['IsPinned'] ?? json['isPinned'] ?? false,
      isArchived: json['IsArchived'] ?? json['isArchived'] ?? false,
      isLocked: json['IsLocked'] ?? json['isLocked'] ?? false,
      sortOrder: json['SortOrder'] ?? json['sortOrder'] ?? 0,
      attachmentCount: json['AttachmentCount'] ?? json['attachmentCount'] ?? 0,
      pinnedAt: _parseDate(json['PinnedAt'] ?? json['pinnedAt']),
      createdAt: _parseDate(json['CreatedAt'] ?? json['createdAt']),
      updatedAt: _parseDate(json['UpdatedAt'] ?? json['updatedAt'] ?? json['updated_at']),
      deletedAt: _parseDate(json['DeletedAt'] ?? json['deletedAt'] ?? json['deleted_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    "NoteId": id,
    "FolderId": folderId,
    "Title": title,
    "Content": content.map((e) => e.toJson()).toList(),
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
  List<NoteModel> get trash => data?.trash ?? [];

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
  final List<NoteModel> trash;

  NoteData({required this.notes, required this.archive, required this.trash});

  factory NoteData.fromJson(Map<String, dynamic> json) {
    // 1. Trust the backend's explicit list categorization first
    final List rawNotes = (json['note'] ?? json['notes'] ?? json['active'] ?? []) as List;
    final List rawArchive = (json['archive'] ?? json['archived'] ?? []) as List;
    final List rawTrash = (json['trash'] ?? json['deleted'] ?? []) as List;
    final List rawData = (json['data'] is List ? json['data'] : []) as List;

    final activeItems = rawNotes.map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e))).where((n) => n.id > 0).toList();
    final archivedItems = rawArchive.map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e))).where((n) => n.id > 0).toList();
    final deletedItems = rawTrash.map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e))).where((n) => n.id > 0).toList();
    final extraItems = rawData.map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e))).where((n) => n.id > 0).toList();

    // 2. Final Lists (Avoiding property re-filtering because properties are inconsistent)
    // We strictly use the list location as the source of truth for the UI
    final finalActive = [...activeItems];
    final finalArchive = [...archivedItems];
    final finalTrash = [...deletedItems];

    // If there are extra notes in 'data', add them to active if not already present elsewhere
    for (var n in extraItems) {
      bool exists = finalActive.any((a) => a.id == n.id) || 
                   finalArchive.any((a) => a.id == n.id) || 
                   finalTrash.any((t) => t.id == n.id);
      if (!exists) finalActive.add(n);
    }

    return NoteData(
      notes: finalActive,
      archive: finalArchive,
      trash: finalTrash,
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
      id: json['id']?.toString() ?? '',
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
      id: json['id']?.toString() ?? '',
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
      id: json['id']?.toString() ?? '', 
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
      id: json['id']?.toString() ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e)))
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
      id: json['id']?.toString() ?? '',
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
      id: json['id']?.toString() ?? '',
      attachmentId: json['attachmentId'] ?? json['Id'] ?? 0,
      displayName: json['displayName'] ?? json['DisplayName'] ?? '',
      url: json['url'] ?? json['Url'],
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
