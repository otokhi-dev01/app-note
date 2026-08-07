import 'package:flutter/material.dart';
import '../../../data/models/note_model.dart';
import '../../../routes/note_navigation.dart';
import '../../../theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../note/controllers/note_controller.dart';

class ArchiveNoteTile extends StatelessWidget {
  final NoteModel note;
  final NoteController controller;

  const ArchiveNoteTile({
    super.key,
    required this.note,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachment = note.content.firstWhereOrNull((b) => b is AttachmentBlock) as AttachmentBlock?;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        NoteNavigation.toDetail(note)?.then((value) {
          if (value == true) controller.fetchNotes();
        });
      },
      leading: note.isPinned 
          ? const Icon(Icons.push_pin, color: AppTheme.folderYellow, size: 16) 
          : null,
      title: Text(
        note.displayTitle,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          "${_formatTime(note.updatedAt)}  ${_getContentSnippet(note)}",
          style: theme.textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: attachment != null
          ? Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: attachment.url != null 
                    ? NetworkImage(attachment.url!) 
                    : const AssetImage('assets/images/placeholder.png') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            )
          : Icon(Icons.chevron_right, color: theme.colorScheme.outline, size: 20),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return "";
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('EEEE').format(date); 
  }

  String _getContentSnippet(NoteModel note) {
    if (note.content.isEmpty) {
      if (note.attachmentCount > 0) {
        return "${note.attachmentCount} attachment${note.attachmentCount > 1 ? 's' : ''}";
      }
      return "No additional text";
    }
    final firstBlock = note.content.firstWhereOrNull((b) => b is TextBlock) as TextBlock?;
    if (firstBlock != null) return firstBlock.text;
    return "Attachment/Checklist";
  }
}
