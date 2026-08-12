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

    return Obx(() {
      final isEditing = controller.isEditing.value;
      final isSelected = controller.selectedNoteIds.contains(note.id);

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        onTap: isEditing
            ? () => controller.toggleSelectNote(note.id)
            : () {
                NoteNavigation.toDetail(note)?.then((value) {
                  if (value == true) controller.fetchNotes(refresh: true);
                });
              },
        leading: isEditing
            ? _buildSelectionIndicator(context, isSelected)
            : (note.isPinned
                ? const Icon(Icons.push_pin, color: AppTheme.folderPink, size: 16)
                : null),
        title: Text(
          note.displayTitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.4,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            "${_formatTime(note.updatedAt)}  ${_getContentSnippet(note)}",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
          size: 20,
        ),
      );
    });
  }

  Widget _buildSelectionIndicator(BuildContext context, bool isSelected) {
    final theme = Theme.of(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.surface, size: 14)
          : null,
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return "";
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('MM/dd/yy').format(date);
  }

  String _getContentSnippet(NoteModel note) {
    if (note.content.isEmpty) {
      return note.attachmentCount > 0 ? "Attachments" : "";
    }
    final firstBlock =
        note.content.firstWhereOrNull((b) => b is TextBlock) as TextBlock?;
    if (firstBlock != null) {
      return NoteModel.extractPlainText(firstBlock.text);
    }
    return "Attachment/Checklist";
  }
}
