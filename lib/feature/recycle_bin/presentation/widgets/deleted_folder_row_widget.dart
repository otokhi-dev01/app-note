import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../folders/domain/entities/folder_entity.dart';
import '../utils/recycle_bin_date_formatter.dart';
import 'recycle_bin_item_row_widget.dart';

class DeletedFolderRowWidget extends StatelessWidget {
  const DeletedFolderRowWidget({
    super.key,
    required this.folder,
    required this.onRestore,
  });

  final FolderEntity folder;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String folderName = folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();

    return RecycleBinItemRowWidget(
      icon: CupertinoIcons.folder_fill,
      iconForegroundColor: colors.error,
      iconBackgroundColor: colors.errorContainer,
      title: folderName,
      description: _folderDescription(),
      onRestore: onRestore,
    );
  }

  String _folderDescription() {
    final String noteLabel =
        '${folder.noteCount} ${folder.noteCount == 1 ? 'note' : 'notes'}';
    final DateTime? timestamp =
        folder.deletedAt ?? folder.updatedAt ?? folder.createdAt;

    if (timestamp == null) {
      return noteLabel;
    }

    return '$noteLabel • ${formatRecycleBinDate(timestamp.toLocal())}';
  }
}
