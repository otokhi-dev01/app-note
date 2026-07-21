import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../folders/domain/entities/folder_entity.dart';
import 'glass_surface_widget.dart';
import 'home_color_utils.dart';

part 'folder_sheet_row_widget.dart';

class HomeFolderSheet extends StatelessWidget {
  final List<FolderEntity> folders;
  final int? selectedFolderId;
  final int totalNoteCount;
  final VoidCallback onSelectAll;
  final ValueChanged<int> onSelectFolder;
  final VoidCallback onCreateFolder;

  const HomeFolderSheet({
    super.key,
    required this.folders,
    required this.selectedFolderId,
    required this.totalNoteCount,
    required this.onSelectAll,
    required this.onSelectFolder,
    required this.onCreateFolder,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return GlassSurface(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      blur: 28,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Folders',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onCreateFolder,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.create_new_folder_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                children: [
                  _FolderSheetRow(
                    icon: Icons.notes_rounded,
                    title: 'All Notes',
                    count: totalNoteCount,
                    selected: selectedFolderId == null,
                    color: colorScheme.primary,
                    onTap: onSelectAll,
                  ),
                  const SizedBox(height: 7),
                  ...folders.map((FolderEntity folder) {
                    final Color folderColor = parseFolderColor(
                      folder.colorValue,
                      colorScheme.primary,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: _FolderSheetRow(
                        icon: Icons.folder_rounded,
                        title: folder.name.trim().isEmpty
                            ? 'Unnamed Folder'
                            : folder.name,
                        count: folder.noteCount,
                        selected: selectedFolderId == folder.id,
                        color: folderColor,
                        onTap: () {
                          onSelectFolder(folder.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
