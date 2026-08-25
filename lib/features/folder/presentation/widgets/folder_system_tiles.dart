import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_glass_icon.dart';

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
          leading: FolderGlassIcon(
            child: Icon(
              CupertinoIcons.trash,
              color: theme.primaryColor,
              size: 21,
            ),
          ),
          title: Text(
            "folder_recently_deleted".tr,
            style: theme.textTheme.bodyLarge,
          ),
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
              FolderGlassIcon(
                color: theme.colorScheme.onSurfaceVariant,
                size: 30,
                borderRadius: 9,
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 13,
                ),
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
          leading: FolderGlassIcon(
            child: Icon(
              CupertinoIcons.archivebox_fill,
              color: theme.primaryColor,
              size: 21,
            ),
          ),
          title: Text("folder_archive".tr, style: theme.textTheme.bodyLarge),
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
              FolderGlassIcon(
                color: theme.colorScheme.onSurfaceVariant,
                size: 30,
                borderRadius: 9,
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
