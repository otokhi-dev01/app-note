import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../domain/entities/note_entity.dart';
import '../controllers/home_controller.dart';

part '../widgets/note_list/note_list_content_widget.dart';
part '../widgets/note_list/note_search_field_widget.dart';
part '../widgets/note_list/create_note_button_widget.dart';
part '../widgets/note_list/folder_filter_strip_widget.dart';
part '../widgets/note_list/folder_filter_chip_widget.dart';
part '../widgets/note_list/note_row_widget.dart';
part '../widgets/note_list/note_icon_widget.dart';
part '../widgets/note_list/note_metadata_widget.dart';
part '../widgets/note_list/note_count_summary_widget.dart';
part '../widgets/note_list/section_header_widget.dart';
part '../widgets/note_list/empty_note_state_widget.dart';
part '../widgets/note_list/no_note_results_state_widget.dart';
part '../widgets/note_list/note_loading_state_widget.dart';
part '../widgets/note_list/note_error_state_widget.dart';
part '../widgets/note_list/state_icon_widget.dart';
part '../widgets/note_list/note_footer_widget.dart';
part '../widgets/note_list/action_sheet_label_widget.dart';

class NoteListView extends GetView<HomeController> {
  const NoteListView({super.key});

  @override
  Widget build(BuildContext context) {
    return _NoteListContent(controller: controller);
  }
}

int _attachmentCount(NoteEntity note) {
  if (note.attachmentCount > 0) {
    return note.attachmentCount;
  }

  return note.content.where((Map<String, dynamic> block) {
    return block['type']?.toString().toLowerCase() == 'attachment';
  }).length;
}

String _notePreview(NoteEntity note) {
  if (note.isLocked) {
    return 'This note is locked.';
  }

  for (final Map<String, dynamic> block in note.content) {
    final String type = block['type']?.toString().toLowerCase() ?? '';

    if (type == 'text') {
      final String text = block['text']?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    if (type == 'checklist') {
      final dynamic rawItems = block['items'];

      if (rawItems is List) {
        final int completed = rawItems.where((dynamic item) {
          return item is Map && item['checked'] == true;
        }).length;

        return '$completed of '
            '${rawItems.length} checklist '
            'tasks completed';
      }

      return 'Checklist';
    }

    if (type == 'attachment') {
      return 'Attachment';
    }
  }

  final int count = _attachmentCount(note);

  if (count > 0) {
    return '$count '
        '${count == 1 ? 'attachment' : 'attachments'}';
  }

  return 'Tap to start writing.';
}

IconData _folderIcon(String value) {
  switch (value.trim().toLowerCase()) {
    case 'work':
    case 'briefcase':
    case 'business':
      return CupertinoIcons.briefcase_fill;

    case 'school':
    case 'education':
      return CupertinoIcons.book_fill;

    case 'personal':
    case 'person':
      return CupertinoIcons.person_fill;

    case 'favorite':
    case 'heart':
      return CupertinoIcons.heart_fill;

    case 'travel':
    case 'flight':
      return CupertinoIcons.airplane;

    case 'home':
      return CupertinoIcons.house_fill;

    case 'code':
      return CupertinoIcons.device_laptop;

    case 'shopping':
      return CupertinoIcons.cart_fill;

    case 'photo':
    case 'photos':
      return CupertinoIcons.photo_fill;

    case 'music':
      return CupertinoIcons.music_note_2;

    case 'idea':
      return CupertinoIcons.lightbulb_fill;

    default:
      return CupertinoIcons.folder_fill;
  }
}

Color _parseFolderColor(String rawValue, Color fallback) {
  final String value = rawValue.trim();

  if (value.isEmpty || value.toLowerCase() == 'string') {
    return fallback;
  }

  try {
    String hex = value
        .replaceAll('#', '')
        .replaceAll('0x', '')
        .replaceAll('0X', '');

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return fallback;
    }

    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return fallback;
  }
}

String _friendlyDate(DateTime date) {
  final DateTime now = DateTime.now();

  final DateTime today = DateTime(now.year, now.month, now.day);

  final DateTime target = DateTime(date.year, date.month, date.day);

  final int difference = today.difference(target).inDays;

  if (difference == 0) {
    return 'Today';
  }

  if (difference == 1) {
    return 'Yesterday';
  }

  if (difference > 1 && difference < 7) {
    return '${difference}d ago';
  }

  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} '
      '${date.day}';
}
