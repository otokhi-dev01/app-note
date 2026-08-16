import 'dart:convert';

class NoteModel {
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
  final bool isDeleteFlag;

  NoteModel({
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

  String get displayTitle => title.isEmpty ? "Untitled Note" : title;

  bool get isDeleted => deletedAt != null || isDeleteFlag;

  static String extractPlainText(dynamic value) {
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
          final decoded = jsonDecode(text);
          return extractPlainText(decoded);
        } catch (_) {}
      }
      return value.trim();
    }
    return value.toString();
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    const String baseUrl = "https://note.piisiit.com";

    final int id = _toInt(json['NoteId'] ?? json['id'] ?? json['Id']);
    final int folderId = _toInt(json['FolderId'] ?? json['folderId']);
    final String title = _toString(json['Title'] ?? json['title']);
    final String folderName = _toString(
      json['FolderName'] ?? json['folderName'],
    );

    // 1. Parse Structured Content from ContentJson
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
            .map((e) => NoteBlock.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    // 2. Parse Attachments and Merge/Add
    final dynamic rawAtts = json['Attachments'] ?? json['attachments'];
    final List rawAttachments = rawAtts is List ? rawAtts : [];

    for (var att in rawAttachments) {
      if (att is! Map) continue;
      final map = Map<String, dynamic>.from(att);
      String blockId = _toString(map['BlockId'] ?? map['blockId']);

      final String? relativePath = _normalizePath(
        _toString(
          map['FilePath'] ?? map['filePath'] ?? map['Url'] ?? map['url'],
        ),
      );
      String? fullUrl;
      if (relativePath != null && relativePath.isNotEmpty) {
        final u = Uri.tryParse(relativePath);
        fullUrl = (u != null && u.hasScheme)
            ? u.toString()
            : Uri.parse(baseUrl).resolve(relativePath).toString();
      }

      int existingIndex = -1;
      if (blockId.isNotEmpty) {
        existingIndex = blocks.indexWhere((b) => b.id == blockId);
      }

      if (existingIndex != -1 && blocks[existingIndex] is AttachmentBlock) {
        // MERGE metadata into existing content block
        final old = blocks[existingIndex] as AttachmentBlock;
        blocks[existingIndex] = AttachmentBlock(
          id: blockId,
          attachmentId: _toInt(
            map['AttachmentId'] ?? map['id'] ?? old.attachmentId,
          ),
          displayName: _toString(
            map['OriginalFileName'] ??
                map['fileName'] ??
                map['Name'] ??
                old.displayName,
          ),
          url: fullUrl ?? old.url,
          localPath: old.localPath,
        );
      } else {
        // ADD as a new block (either blockId is new or missing)
        // If blockId is missing, we use attachmentId as a temporary unique ID
        final attId = _toInt(map['AttachmentId'] ?? map['id']);
        final finalBlockId = blockId.isNotEmpty ? blockId : "att_$attId";
        
        blocks.add(
          AttachmentBlock(
            id: finalBlockId,
            attachmentId: attId,
            displayName: _toString(
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

    // 3. Fallback to plain text if blocks still empty
    if (blocks.isEmpty) {
      final String plainText = _toString(
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
      isPinned: _toBool(json['IsPinned'] ?? json['isPinned']),
      isArchived: _toBool(json['IsArchived'] ?? json['isArchived']),
      isLocked: _toBool(json['IsLocked'] ?? json['isLocked']),
      updatedAt: _parseDate(json['UpdatedAt'] ?? json['updatedAt']),
      deletedAt: _parseDate(json['DeletedAt'] ?? json['deletedAt']),
      isDeleteFlag: _toBool(json['IsDelete'] ?? json['isDelete']),
      attachmentCount: _toInt(
        json['AttachmentCount'] ?? json['attachmentCount'],
      ),
    );
  }

  static String? _normalizePath(String path) {
    if (path.isEmpty) return null;
    return path.trim().replaceAll('\\', '/').replaceFirst('~/', '');
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
    "NoteId": id,
    "FolderId": folderId,
    "Title": title,
    "ContentJson": content.map((e) => e.toJson()).toList(),
  };
}

abstract class NoteBlock {
  final String id;
  final String type;

  NoteBlock({required this.id, required this.type});

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    final type = _toString(json['type'] ?? json['Type']).toLowerCase();
    final id = _toString(json['id'] ?? json['Id']);

    switch (type) {
      case 'text':
        return TextBlock.fromJson(json);
      case 'checklist':
        return ChecklistBlock.fromJson(json);
      case 'attachment':
        return AttachmentBlock.fromJson(json);
      case 'table':
        return TableBlock.fromJson(json);
      case 'drawing':
        return DrawingBlock.fromJson(json);
      default:
        return TextBlock(id: id, text: 'Unknown block type: $type');
    }
  }

  Map<String, dynamic> toJson();
}

class TextBlock extends NoteBlock {
  final String text;
  final String style;

  TextBlock({required String id, required this.text, this.style = 'body'})
    : super(id: id, type: 'text');

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(
      id: _toString(json['id'] ?? json['Id']),
      text: _parseTextContent(json['text'] ?? json['Text'] ?? json['content']),
      style: _toString(json['style'] ?? json['Style'] ?? 'body'),
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
    : super(id: id, type: 'checklist');

  factory ChecklistBlock.fromJson(Map<String, dynamic> json) {
    final dynamic rawItemsData = json['items'] ?? json['Items'];
    final List rawItems = rawItemsData is List ? rawItemsData : [];
    return ChecklistBlock(
      id: _toString(json['id'] ?? json['Id']),
      items: rawItems
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
      id: _toString(json['id'] ?? json['Id']),
      text: _toString(json['text'] ?? json['Text']),
      checked: _toBool(json['checked'] ?? json['Checked']),
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "text": text, "checked": checked};
}

class AttachmentBlock extends NoteBlock {
  final int attachmentId;
  final String displayName;
  final String? url;
  final String? localPath;

  AttachmentBlock({
    required String id,
    this.attachmentId = 0,
    required this.displayName,
    this.url,
    this.localPath,
  }) : super(id: id, type: 'attachment');

  factory AttachmentBlock.fromJson(Map<String, dynamic> json) {
    return AttachmentBlock(
      id: _toString(json['id'] ?? json['Id'] ?? json['BlockId']),
      attachmentId: _toInt(
        json['attachmentId'] ?? json['AttachmentId'] ?? json['id'],
      ),
      displayName: _toString(
        json['displayName'] ?? json['DisplayName'] ?? json['Name'],
      ),
      url: _toString(json['url'] ?? json['Url'] ?? json['FilePath']),
      localPath: _toString(json['localPath']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "type": "attachment",
    "attachmentId": attachmentId,
    "displayName": displayName,
    if (url != null) "url": url,
  };
}

class TableBlock extends NoteBlock {
  final List<List<String>> rows;
  TableBlock({required String id, required this.rows})
    : super(id: id, type: 'table');
  factory TableBlock.fromJson(Map<String, dynamic> json) {
    final dynamic rawRowsData = json['rows'] ?? json['Rows'];
    final List rawRows = rawRowsData is List ? rawRowsData : [];
    return TableBlock(
      id: _toString(json['id'] ?? json['Id']),
      rows: rawRows
          .map(
            (r) =>
                (r is List) ? r.map((c) => _toString(c)).toList() : <String>[],
          )
          .toList(),
    );
  }
  @override
  Map<String, dynamic> toJson() => {"id": id, "type": "table", "rows": rows};
}

class DrawingBlock extends NoteBlock {
  final String? localPath;
  final String? url;
  DrawingBlock({required String id, this.localPath, this.url})
    : super(id: id, type: 'drawing');
  factory DrawingBlock.fromJson(Map<String, dynamic> json) {
    return DrawingBlock(
      id: _toString(json['id'] ?? json['Id']),
      localPath: _toString(json['localPath']),
      url: _toString(json['url'] ?? json['Url']),
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

// --- SAFE PARSERS (Task 9) ---

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String _toString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1';
}

String _parseTextContent(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is List || value is Map) return jsonEncode(value);
  return value.toString();
}
