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
          leading: Icon(folder.icon, color: folder.color, size: 25),
          title: Text(
            folder.name,
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
              : Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.2,
                  ),
                  size: 20,
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
