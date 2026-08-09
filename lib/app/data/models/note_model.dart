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

    // Support various naming conventions for ID and Title
    final int id = json['NoteId'] ?? json['id'] ?? json['Id'] ?? 0;
    final String title =
        (json['Title'] ?? json['title'] ?? json['Name'] ?? json['name'] ?? '')
            .toString()
            .trim();
    final int folderId =
        json['FolderId'] ?? json['folderId'] ?? json['Folder_Id'] ?? 0;
    final String folderName = (json['FolderName'] ?? json['folderName'] ?? '')
        .toString()
        .trim();

    // 1. Parse Content (Text, Checklists, etc.)
    // Logic: Find the first field that has actual content (not null and not an empty list/string)
    dynamic contentData;
    final contentFields = [
      'ContentJson',
      'Content',
      'content',
      'NoteContent',
      'blocks',
      'data',
      'Body',
      'body',
      'NoteText',
      'text',
      'Description',
      'description',
      'NoteDescription',
      'ContentText',
    ];

    // Explicitly prioritize known JSON string fields
    for (var field in contentFields) {
      final value = json[field];
      if (value != null) {
        if (value is List && value.isNotEmpty) {
          contentData = value;
          break;
        } else if (value is String &&
            value.trim().isNotEmpty &&
            value != '[]' &&
            value != '{}') {
          // If it's a string, we hope it's our JSON array string
          contentData = value;
          break;
        }
      }
    }

    List<NoteBlock> parsedContent = [];

    if (contentData is List) {
      parsedContent = contentData
          .map((e) => NoteBlock.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (contentData is Map) {
      // Handle single block object
      try {
        parsedContent = [
          NoteBlock.fromJson(Map<String, dynamic>.from(contentData)),
        ];
      } catch (_) {
        if (kDebugMode) debugPrint("Failed to parse Content Map: $contentData");
      }
    } else if (contentData is String && contentData.isNotEmpty) {
      try {
        final decoded = jsonDecode(contentData);
        if (decoded is List) {
          parsedContent = decoded
              .map((e) => NoteBlock.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (decoded is Map) {
          parsedContent = [
            NoteBlock.fromJson(Map<String, dynamic>.from(decoded)),
          ];
        } else {
          // If it's valid JSON but not a list/map (e.g. a string), handle as plain text
          parsedContent = [
            TextBlock(id: 'text_initial', text: decoded.toString()),
          ];
        }
      } catch (_) {
        // Fallback for plain text that isn't JSON
        parsedContent = [TextBlock(id: 'text_initial', text: contentData)];
      }
    }

    // 2. Parse Attachments (Images/Videos) and MERGE into content blocks
    final dynamic rawAttachmentsData =
        json['Attachments'] ?? json['attachments'] ?? [];
    final List attachmentsList = rawAttachmentsData is List
        ? rawAttachmentsData
        : [rawAttachmentsData];

    for (var att in attachmentsList) {
      if (att == null) continue;
      final map = Map<String, dynamic>.from(att as Map);
      final String blockId = (map['BlockId'] ?? map['blockId'] ?? '')
          .toString();

      final String? relativePath = _normalizeAttachmentPath(
        map['FilePath'] ??
            map['filePath'] ??
            map['FileUrl'] ??
            map['fileUrl'] ??
            map['Path'] ??
            map['path'] ??
            map['Url'] ??
            map['url'],
      );

      String? fullUrl;
      if (relativePath != null && relativePath.isNotEmpty) {
        final u = Uri.tryParse(relativePath);
        if (u != null && u.hasScheme) {
          fullUrl = u.toString();
        } else {
          fullUrl = Uri.parse(baseUrl).resolve(relativePath).toString();
        }
      }

      // Check if this attachment is already represented in content blocks
      int existingIndex = parsedContent.indexWhere((b) => b.id == blockId);

      if (existingIndex != -1 &&
          parsedContent[existingIndex] is AttachmentBlock) {
        // UPDATE existing block with full URL and server metadata
        final oldBlock = parsedContent[existingIndex] as AttachmentBlock;
        parsedContent[existingIndex] = AttachmentBlock(
          id: blockId,
          attachmentId:
              map['AttachmentId'] ?? map['id'] ?? oldBlock.attachmentId,
          displayName:
              map['OriginalFileName'] ??
              map['fileName'] ??
              map['Name'] ??
              map['name'] ??
              oldBlock.displayName,
          url: fullUrl ?? oldBlock.url,
          localPath: oldBlock.localPath,
        );
      } else {
        // ADD new block if not present
        parsedContent.add(
          AttachmentBlock(
            id: blockId.isEmpty
                ? DateTime.now().millisecondsSinceEpoch.toString()
                : blockId,
            attachmentId: map['AttachmentId'] ?? map['id'] ?? 0,
            displayName:
                map['OriginalFileName'] ??
                map['fileName'] ??
                map['Name'] ??
                map['name'] ??
                'Attachment',
            url: fullUrl,
            localPath: null,
          ),
        );
      }
    }

    return NoteModel(
      id: id,
      folderId: folderId,
      folderName: folderName,
      title: title,
      content: parsedContent,
      isPinned: json['IsPinned'] ?? json['isPinned'] ?? json['pinned'] ?? false,
      isArchived:
          json['IsArchived'] ?? json['isArchived'] ?? json['archived'] ?? false,
      isLocked: json['IsLocked'] ?? json['isLocked'] ?? json['locked'] ?? false,
      sortOrder: json['SortOrder'] ?? json['sortOrder'] ?? 0,
      attachmentCount: json['AttachmentCount'] ?? json['attachmentCount'] ?? 0,
      pinnedAt: _parseDate(json['PinnedAt'] ?? json['pinnedAt']),
      createdAt: _parseDate(json['CreatedAt'] ?? json['createdAt']),
      updatedAt: _parseDate(
        json['UpdatedAt'] ?? json['updatedAt'] ?? json['updated_at'],
      ),
      deletedAt: _parseDate(
        json['DeletedAt'] ?? json['deletedAt'] ?? json['deleted_at'],
      ),
    );
  }

  static String? _normalizeAttachmentPath(dynamic value) {
    if (value == null) return null;

    String? result;
    if (value is List && value.isNotEmpty) {
      result = value.first?.toString();
    } else if (value is Map) {
      result = value['path']?.toString() ?? value['url']?.toString();
    } else {
      result = value.toString();
    }

    result = result?.trim();
    if (result == null || result.isEmpty) return null;

    if (result.startsWith('[') && result.endsWith(']')) {
      result = result.substring(1, result.length - 1).trim();
    }
    if (result.startsWith('(') && result.endsWith(')')) {
      result = result.substring(1, result.length - 1).trim();
    }

    // Remove markdown-like wrapper tokens such as [path]() or path() if present.
    result = result.replaceAll(RegExp(r'^\s*\[([^\]]+)\]\(\)\s* ?'), r'$1').trim();
    result = result.replaceAll(RegExp(r'\s*\(([^\)]+)\)\s* ?'), r'$1').trim();

    final match = RegExp(r'(/[^)\]\s]+\.[\w\d]+)').firstMatch(result);
    if (match != null) {
      result = match.group(0)!;
    }

    return result.isEmpty ? null : result;
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
    // 1. Helper to safely parse a list or a single object into a list
    List<NoteModel> _parseList(dynamic listData) {
      if (listData == null) return [];
      if (listData is List) {
        return listData
            .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e)))
            .where((n) => n.id > 0)
            .toList();
      }
      if (listData is Map) {
        final note = NoteModel.fromJson(Map<String, dynamic>.from(listData));
        return note.id > 0 ? [note] : [];
      }
      return [];
    }

    // 2. Extract and parse all potential locations
    final activeItems = _parseList(
      json['note'] ?? json['notes'] ?? json['active'],
    );
    final archivedItems = _parseList(json['archive'] ?? json['archived']);
    final deletedItems = _parseList(json['trash'] ?? json['deleted']);
    final extraItems = _parseList(json['data'] is List ? json['data'] : null);

    // 3. Final Lists (Avoiding property re-filtering because properties are inconsistent)
    final finalActive = [...activeItems];
    final finalArchive = [...archivedItems];
    final finalTrash = [...deletedItems];

    // If there are extra notes in 'data' list, add them to active if not already present elsewhere
    for (var n in extraItems) {
      bool exists =
          finalActive.any((a) => a.id == n.id) ||
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
    final type = (json['type'] ?? json['Type'] ?? 'text')
        .toString()
        .toLowerCase();
    final id =
        (json['id'] ??
                json['Id'] ??
                DateTime.now().microsecondsSinceEpoch.toString())
            .toString();
    final data = Map<String, dynamic>.from(json)..['id'] = id;

    if (type == 'text') return TextBlock.fromJson(data);
    if (type == 'checklist') return ChecklistBlock.fromJson(data);
    if (type == 'attachment') return AttachmentBlock.fromJson(data);
    if (type == 'table') return TableBlock.fromJson(data);
    if (type == 'drawing') return DrawingBlock.fromJson(data);

    // Fallback for unknown types - treat as text to avoid crashing
    return TextBlock(
      id: id,
      text: "Unknown block type ($type): ${json.toString()}",
      style: 'body',
    );
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
    "Id": id, // Reverting to String
    "Type": "drawing",
    "LocalPath": localPath,
    "Url": url,
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
    "Id": id, // Reverting to String
    "Type": "table",
    "Rows": rows,
  };
}

class TextBlock extends NoteBlock {
  final String text; // Stores plain text or Delta JSON
  final String style; // 'title', 'heading', 'subheading', 'body'

  TextBlock({required String id, required this.text, this.style = 'body'})
    : super(id: id, type: BlockType.text);

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    final rawText = json['text'] ?? json['Text'] ?? '';
    String textValue;
    if (rawText is String) {
      textValue = rawText;
    } else {
      // If server returned structured JSON, convert it back to String for our internal state
      textValue = jsonEncode(rawText);
    }

    return TextBlock(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      text: textValue,
      style: (json['style'] ?? json['Style'] ?? 'body').toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    // Preserve text as a JSON string for server compatibility.
    // The backend often expects Text to be the raw Delta string, not an already-decoded Dart object.
    final String textValue = text;

    return {"Id": id, "Type": "text", "Text": textValue, "Style": style};
  }
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
    "Id": id, // Reverting to String
    "Type": "checklist",
    "Items": items.map((e) => e.toJson()).toList(),
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
    "Id": id.toString(),
    "Text": text.toString(),
    "Checked": checked,
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
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "Id": id, // Reverting to String as required by server
      "Type": "attachment",
      "AttachmentId": attachmentId,
      "DisplayName": displayName,
    };
    if (url != null) data["Url"] = url;
    return data;
  }
}
