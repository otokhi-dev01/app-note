import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:Note/routes/app_pages.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_context_menu.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/presentation/widgets/folder_glass_icon.dart';

class FolderTile extends StatefulWidget {
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
  State<FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends State<FolderTile> {
  // Owned by the tile (not rebuilt with it) so long-press, the edit-mode tap,
  // and the "..." button can all drive the same open menu across rebuilds —
  // see FolderContextMenu's doc comment for why this can't be a triggerBuilder.
  final _menuController = lg.GlassMenuController();

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final controller = widget.controller;
    final theme = Theme.of(context);
    final leftPadding = 20.0 + (widget.depth * 20.0);

    return Obx(() {
      final isEditing = controller.isEditing.value;
      final isSystem = controller.isSystemFolder(folder);
      final isShortView = controller.viewMode.value == 'short';

      return Stack(
        children: [
          Opacity(
            opacity: (isEditing && isSystem) ? 0.3 : 1.0,
            child: CustomGlassListTile(
              contentPadding: EdgeInsets.only(
                left: leftPadding,
                right: 20,
                top: isShortView ? 0 : 4,
                bottom: isShortView ? 0 : 4,
              ),
              onTap: (isEditing && isSystem)
                  ? null
                  : () {
                      if (isEditing && !isSystem) {
                        _menuController.open();
                      } else {
                        Get.toNamed(
                          Routes.NOTE_LIST,
                          arguments: folder,
                        )?.then((value) => controller.fetchFolders());
                      }
                    },
              onLongPress: isSystem ? null : () => _menuController.open(),
              // Renders the icon + color chosen in the folder editor
              leading: FolderGlassIcon(
                color: folder.color,
                child: FolderGlyph(folder: folder, size: 22),
              ),
              title: Text(
                folder.displayName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              subtitle: isShortView
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "folder_tile_subtitle".trParams({
                          'count': '${folder.noteCount}',
                        }),
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
                          onPressed: () => _menuController.open(),
                          icon: FolderGlassIcon(
                            color: AppTheme.folderPink,
                            size: 28,
                            borderRadius: 14,
                            child: const Icon(
                              Icons.more_horiz,
                              color: AppTheme.folderPink,
                              size: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        FolderGlassIcon(
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 32,
                          borderRadius: 9,
                          child: Icon(
                            Icons.reorder,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                      ],
                    )
                  : folder.subFolders.isNotEmpty
                  ? _ExpandToggle(controller: controller, folder: folder)
                  : FolderGlassIcon(
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 32,
                      borderRadius: 9,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                    ),
            ),
          ),
          // Anchors the menu's morph near the "..." button/top-right corner
          // regardless of which trigger (long-press, tap, button) opened it.
          Positioned(
            top: 8,
            right: 16,
            child: FolderContextMenu(
              folder: folder,
              controller: controller,
              menuController: _menuController,
            ),
          ),
        ],
      );
    });
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
            child: FolderGlassIcon(
              color: theme.colorScheme.onSurfaceVariant,
              size: 32,
              borderRadius: 9,
              child: Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurfaceVariant,
                size: 14,
              ),
            ),
          ),
        ),
      );
    });
  }
}
