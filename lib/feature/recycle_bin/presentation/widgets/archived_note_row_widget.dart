import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../notes/domain/entities/note_entity.dart';
import '../utils/recycle_bin_date_formatter.dart';
import 'recycle_bin_item_row_widget.dart';

class ArchivedNoteRowWidget extends StatelessWidget {
  const ArchivedNoteRowWidget({
    super.key,
    required this.note,
    required this.onRestore,
  });

  final NoteEntity note;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String title = note.title.trim().isEmpty
        ? 'Untitled Note'
        : note.title.trim();
    final String folderName = note.folderName.trim().isEmpty
        ? 'Notes'
        : note.folderName.trim();
    final DateTime? timestamp = note.updatedAt ?? note.createdAt;
    final String description = timestamp == null
        ? folderName
        : '$folderName • ${formatRecycleBinDate(timestamp.toLocal())}';

    return RecycleBinItemRowWidget(
      icon: CupertinoIcons.archivebox_fill,
      iconForegroundColor: colors.primary,
      iconBackgroundColor: colors.primaryContainer,
      title: title,
      description: description,
      onRestore: onRestore,
    );
  }
}
