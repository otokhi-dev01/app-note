import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';
import '../controllers/folder_controller.dart';
import 'folder_context_menu.dart';

class FolderTile extends StatelessWidget {
  final FolderModel folder;
  final FolderController controller;

  const FolderTile({super.key, required this.folder, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;
      final isSystem = controller.isSystemFolder(folder);

      return Opacity(
        opacity: (isEditing && isSystem) ? 0.3 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
          leading:  Icon(
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
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
    Get.dialog(
      FolderContextMenu(folder: folder, controller: controller),
      barrierColor: Colors.black.withValues(alpha: 0.1),
    );
  }
}
