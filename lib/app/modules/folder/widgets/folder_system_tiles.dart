import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/folder_controller.dart';

class FolderSystemTiles extends StatelessWidget {
  final FolderController controller;

  const FolderSystemTiles({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildArchiveTile(context),
        const Divider(indent: 56, height: 1),
        _buildRecentlyDeletedTile(context),
        const Divider(indent: 56, height: 1),
        _buildPinnedTile(context),
        const Divider(indent: 56, height: 1),
        _buildTrashTile(context),
        const Divider(indent: 56, height: 1),
        _buildProfileTile(context),
      ],
    );
  }

  Widget _buildPinnedTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;
      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.PINNED),
          leading: Icon(
            Icons.push_pin_outlined,
            color: theme.primaryColor,
            size: 30,
          ),
          title: Text("Pinned", style: theme.textTheme.bodyLarge),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${controller.pinnedNotesCount.value}",
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

  Widget _buildRecentlyDeletedTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;
      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.RECENTLY_DELETED),
          leading: Icon(
            Icons.delete_outline_rounded,
            color: theme.primaryColor,
            size: 30,
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
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.ARCHIVE),
          leading: Icon(
            Icons.archive_outlined,
            color: theme.primaryColor,
            size: 30,
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

  Widget _buildProfileTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;
      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.PROFILE),
          leading: Icon(
            Icons.person_outline,
            color: theme.primaryColor,
            size: 30,
          ),
          title: Text("Profile", style: theme.textTheme.bodyLarge),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            size: 20,
          ),
        ),
      );
    });
  }

  Widget _buildTrashTile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;
      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing ? null : () => Get.toNamed(Routes.TRASH),
          leading: Icon(
            Icons.delete_sweep_rounded,
            color: theme.primaryColor,
            size: 30,
          ),
          title: Text("Trash", style: theme.textTheme.bodyLarge),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            size: 20,
          ),
        ),
      );
    });
  }
}
