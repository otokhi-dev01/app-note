import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';

class FolderAllNotesTile extends StatelessWidget {
  final FolderController controller;

  const FolderAllNotesTile({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isEditing = controller.isEditing.value;

      return Opacity(
        opacity: isEditing ? 0.15 : 1.0,
        child: CustomGlassListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: isEditing
              ? null
              : () => Get.toNamed(
                  Routes.NOTE_LIST,
                  arguments: Folder(
                    id: 0,
                    name: "All on My iphone",
                    iconName: "folder",
                    colorValue: "#FFB703",
                    sortOrder: 0,
                  ),
                ),
          leading: Icon(
            CupertinoIcons.folder,
            color: theme.primaryColor,
            size: 25,
          ),
          title: Text(
            "All on My iphone",
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${controller.allNotesCount.value}",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                size: 16,
              ),
            ],
          ),
        ),
      );
    });
  }
}
