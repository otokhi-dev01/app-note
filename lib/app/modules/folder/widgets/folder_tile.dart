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

  const FolderTile({
    super.key,
    required this.folder,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;
      final isSystem = controller.isSystemFolder(folder);

      return Opacity(
        opacity: (isEditing && isSystem) ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: (isEditing && isSystem)
              ? null
              : () => Get.toNamed(Routes.NOTE_LIST, arguments: folder)?.then((value) => controller.fetchFolders()),
          leading: Icon(folder.icon, color: AppTheme.folderYellow, size: 30),
          title: Text(folder.name, style: theme.textTheme.bodyLarge),
          trailing: isEditing && !isSystem
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => Get.dialog(
                        FolderContextMenu(folder: folder, controller: controller),
                        barrierColor: Colors.black.withValues(alpha: 0.1),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.folderYellow, width: 1.5),
                        ),
                        child: const Icon(Icons.more_horiz, color: AppTheme.folderYellow, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.reorder, color: theme.colorScheme.onSurfaceVariant, size: 24),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${folder.noteCount}", style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 20),
                  ],
                ),
        ),
      );
    });
  }
}
