import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';

class FolderSystemTiles extends StatelessWidget {
  final FolderController controller;

  const FolderSystemTiles({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        _buildArchiveTile(context),
        const Divider(indent: 56, height: 20, thickness: 0.5),
        _buildRecentlyDeletedTile(context),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecentlyDeletedTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;
      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: CustomGlassListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.RECENTLY_DELETED),
          leading: Icon(
            CupertinoIcons.trash, // Updated to use CupertinoIcons.folder
            color: theme.primaryColor,
            size: 25,
          ),
          title: Text("Recently Deleted", style: theme.textTheme.bodyLarge),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${controller.deletedCount.value}",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                size: 20,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildArchiveTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;
      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: CustomGlassListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.ARCHIVE),
          leading: Icon(
            CupertinoIcons.folder,
            color: theme.primaryColor,
            size: 25,
          ),
          title: Text("Archive", style: theme.textTheme.bodyLarge),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${controller.archivedCount.value}",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                size: 20,
              ),
            ],
          ),
        ),
      );
    });
  }
}
