import 'package:flutter/material.dart';

class FolderModel {
  final int id;
  final String name;
  final String iconName;
  final String colorValue;
  final int sortOrder;
  final int noteCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  FolderModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.sortOrder,
    this.noteCount = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: _toInt(json['FolderId'] ?? json['id'] ?? json['Id']),
      name: (json['FolderName'] ?? json['Name'] ?? json['name'] ?? '')
          .toString()
          .trim(),
      iconName: json['IconName'] ?? json['iconName'] ?? '',
      colorValue: json['ColorValue'] ?? json['colorValue'] ?? '',
      sortOrder: _toInt(json['SortOrder'] ?? json['sortOrder']),
      noteCount: _toInt(json['NoteCount'] ?? json['noteCount']),
      createdAt: _parseDate(json['CreatedAt'] ?? json['createdAt']),
      updatedAt: _parseDate(json['UpdatedAt'] ?? json['updatedAt']),
      deletedAt: _parseDate(json['DeletedAt'] ?? json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        "FolderId": id,
        "Name": name,
        "IconName": iconName,
        "ColorValue": colorValue,
        "SortOrder": sortOrder,
      };

  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'work':
        return Icons.work_outline;
      case 'school':
        return Icons.school_outlined;
      case 'favorite':
        return Icons.favorite_border;
      case '5':
        return Icons.code_rounded;
      case 'folder':
        return Icons.folder_open_rounded;
      default:
        return Icons.folder_open_rounded;
    }
  }

  Color get color {
    if (colorValue.isEmpty) return const Color(0xFFFF69B4);
    if (colorValue.startsWith('#')) {
      return Color(int.parse(colorValue.replaceFirst('#', '0xFF')));
    }
    return Color(int.tryParse(colorValue) ?? 0xFFFF69B4);
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

class FolderResponse {
  final List<FolderModel> folders;
  final List<FolderModel> trash;
  final int code;
  final String message;

  FolderResponse({
    required this.folders,
    required this.trash,
    required this.code,
    required this.message,
  });

  factory FolderResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    List<FolderModel> activeList = [];
    List<FolderModel> trashList = [];

    if (rawData is Map) {
      final List rawFolderList = (rawData['folder'] ?? []) as List;
      final List rawArchiveList = (rawData['archive'] ?? []) as List;
      final List rawTrashList = (rawData['trash'] ?? []) as List;

      // Parse and filter
      final allItems = [
        ...rawFolderList.map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e))),
        ...rawArchiveList.map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e))),
      ];

      activeList = allItems.where((f) => f.deletedAt == null).toList();
      
      // Combine explicit trash with soft-deleted items found in main lists
      final explicitTrash = rawTrashList.map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e))).toList();
      final implicitTrash = allItems.where((f) => f.deletedAt != null).toList();
      trashList = [...explicitTrash, ...implicitTrash];

    } else if (rawData is List) {
      final all = rawData.map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e))).toList();
      activeList = all.where((f) => f.deletedAt == null).toList();
      trashList = all.where((f) => f.deletedAt != null).toList();
    }

    return FolderResponse(
      folders: activeList,
      trash: trashList,
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
