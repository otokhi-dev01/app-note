import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/folder_controller.dart';
import 'folder_context_menu.dart';

class FolderTile extends StatelessWidget {
  final FolderModel folder;
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
          leading: Icon(
            CupertinoIcons.folder, // Updated to use CupertinoIcons.folder
            color: theme.primaryColor,
            size: 25,
          ),
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
