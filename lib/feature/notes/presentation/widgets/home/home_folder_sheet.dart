import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../folders/domain/entities/folder_entity.dart';
import 'glass_surface_widget.dart';
import 'home_color_utils_widget.dart';

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
    final ColorScheme colorScheme =
        theme.colorScheme;

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
                color: colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.28),
                borderRadius:
                BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                12,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Folders',
                      style: theme
                          .textTheme.headlineSmall
                          ?.copyWith(
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
                        color: colorScheme.primary
                            .withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons
                            .create_new_folder_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  0,
                  14,
                  20,
                ),
                children: [
                  _FolderSheetRow(
                    icon: Icons.notes_rounded,
                    title: 'All Notes',
                    count: totalNoteCount,
                    selected:
                    selectedFolderId == null,
                    color: colorScheme.primary,
                    onTap: onSelectAll,
                  ),
                  const SizedBox(height: 7),
                  ...folders.map(
                        (FolderEntity folder) {
                      final Color folderColor =
                      parseFolderColor(
                        folder.colorValue,
                        colorScheme.primary,
                      );

                      return Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 7,
                        ),
                        child: _FolderSheetRow(
                          icon: Icons.folder_rounded,
                          title:
                          folder.name.trim().isEmpty
                              ? 'Unnamed Folder'
                              : folder.name,
                          count: folder.noteCount,
                          selected:
                          selectedFolderId ==
                              folder.id,
                          color: folderColor,
                          onTap: () {
                            onSelectFolder(folder.id);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderSheetRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FolderSheetRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Material(
      color: selected
          ? color.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                  color.withValues(alpha: 0.13),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: color,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  theme.textTheme.titleMedium
                      ?.copyWith(
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
              ),
              Container(
                constraints:
                const BoxConstraints(
                  minWidth: 29,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface
                      .withValues(alpha: 0.055),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style:
                  theme.textTheme.labelSmall
                      ?.copyWith(
                    color:
                    colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                size: selected ? 21 : 20,
                color: selected
                    ? color
                    : colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}