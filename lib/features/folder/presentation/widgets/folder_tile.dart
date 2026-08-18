import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_context_menu.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';

class FolderTile extends StatelessWidget {
  final Folder folder;
  final FolderController controller;
  final int depth;

  const FolderTile({
    super.key,
    required this.folder,
    required this.controller,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leftPadding = 20.0 + (depth * 20.0);

    return Obx(() {
      final isEditing = controller.isEditing.value;
      final isSystem = controller.isSystemFolder(folder);

      return Opacity(
        opacity: (isEditing && isSystem) ? 0.3 : 1.0,
        child: CustomGlassListTile(
          contentPadding: EdgeInsets.only(
            left: leftPadding,
            right: 20,
            top: 4,
            bottom: 4,
          ),
          onTap: (isEditing && isSystem)
              ? null
              : () {
                  if (isEditing && !isSystem) {
                    _showContextMenu(context);
                  } else {
                    Get.toNamed(
                      Routes.NOTE_LIST,
                      arguments: folder,
                    )?.then((value) => controller.fetchFolders());
                  }
                },
          onLongPress: isSystem ? null : () => _showContextMenu(context),
          // Renders the icon + color chosen in the folder editor
          leading: FolderGlyph(folder: folder, size: 25),
          title: Text(
            folder.displayName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              "Folder  •  ${folder.noteCount} notes",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
                fontSize: 13,
              ),
            ),
          ),
          trailing: isEditing && !isSystem
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showContextMenu(context),
                      icon: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.folderPink,
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: AppTheme.folderPink,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.reorder,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      size: 22,
                    ),
                  ],
                )
              : folder.subFolders.isNotEmpty
              ? _ExpandToggle(controller: controller, folder: folder)
              : Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.2,
                  ),
                  size: 16,
                ),
        ),
      );
    });
  }

  void _showContextMenu(BuildContext context) {
    FolderContextMenu.show(
      context: context,
      folder: folder,
      controller: controller,
    );
  }
}

/// The disclosure arrow on a folder that has subfolders — tapping it
/// expands/collapses just that folder's children, same feature as the
/// "On My iPhone" section header but scoped to one folder. Its own tap
/// target keeps it independent from the tile's row tap (which opens the
/// folder's notes).
class _ExpandToggle extends StatelessWidget {
  final FolderController controller;
  final Folder folder;

  const _ExpandToggle({required this.controller, required this.folder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final expanded = controller.isFolderExpanded(folder.id);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.toggleFolderExpanded(folder.id),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedRotation(
            turns: expanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.35,
              ),
              size: 16,
            ),
          ),
        ),
      );
    });
  }
}
