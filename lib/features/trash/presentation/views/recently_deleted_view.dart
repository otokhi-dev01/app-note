import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/core/utils/date_formatter.dart';
import 'package:Note/core/utils/note_snippet.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/ios_confirmation_dialog.dart';
import 'package:Note/features/trash/presentation/controllers/recently_deleted_controller.dart';
import 'package:Note/features/trash/presentation/widgets/slidable_note_tile.dart';
import 'package:Note/features/trash/presentation/widgets/trash_item_context_menu.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';

class RecentlyDeletedView extends GetView<RecentlyDeletedController> {
  const RecentlyDeletedView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: RefreshIndicator(
          onRefresh: () => controller.fetchDeletedItems(),
          color: theme.primaryColor,
          backgroundColor: theme.scaffoldBackgroundColor,
          edgeOffset: 140,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              _buildRecentlyDeletedHeader(context),
              _buildDeletedItemsList(context),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
        bottomNavigationBar: Obx(() {
          if (controller.isEditing.value) {
            return _buildEditBottomBar(context);
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return CustomGlassSliverAppBar(
      expandedHeight: 140,
      toolbarHeight: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      centerTitle: true,
      title: Text(
        "trash_title".tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      leading: CustomGlassButton(
        onPressed: () => Get.back(),
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        padding: EdgeInsets.zero,
        child: Icon(
          CupertinoIcons.chevron_left,
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Obx(
            () => controller.isEditing.value
                ? CustomGlassButton(
                    onPressed: controller.toggleEditing,
                    width: 44,
                    height: 44,
                    shape: GlassShape.circle,
                    blur: 10,
                    opacity: 0.15,
                    thickness: 8,
                    padding: EdgeInsets.zero,
                    child: Icon(
                      Icons.check,
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                  )
                : CustomGlassButton(
                    onPressed: controller.toggleEditing,
                    height: 44,
                    borderRadius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    blur: 10,
                    opacity: 0.15,
                    thickness: 8,
                    child: Text(
                      "trash_edit".tr,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 17,
                      ),
                    ),
                  ),
          ),
        ),
      ],
      largeTitleAlignment: Alignment.bottomCenter,
      largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      largeTitle: Text(
        "trash_title".tr,
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 27,
        ),
      ),
    );
  }

  Widget _buildRecentlyDeletedHeader(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Obx(() {
          final totalItems =
              controller.deletedNotes.length + controller.deletedFolders.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'trash_item_count_one'.trPluralParams(
                  'trash_item_count_other',
                  totalItems,
                  {'count': '$totalItems'},
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "trash_retention_notice".tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                  height: 1.3,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDeletedItemsList(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.folderPink),
          ),
        );
      }

      final hasFolders = controller.deletedFolders.isNotEmpty;
      final hasNotes = controller.deletedNotes.isNotEmpty;

      if (!hasFolders && !hasNotes) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomGlassContainer(
                    width: 72,
                    height: 72,
                    borderRadius: 20,
                    blur: 16,
                    opacity: 0.12,
                    thickness: 7,
                    refractiveIndex: 1.1,
                    glassColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.trash,
                      size: 30,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "trash_empty_state".tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (hasFolders && hasNotes) {
              if (index == 0) {
                return _buildSection(
                  context,
                  "trash_folders_section".tr,
                  controller.deletedFolders,
                  isFolder: true,
                );
              }
              if (index == 1) {
                return _buildSection(
                  context,
                  "trash_notes_section".tr,
                  controller.deletedNotes,
                  isFolder: false,
                );
              }
            } else if (hasFolders) {
              if (index == 0) {
                return _buildSection(
                  context,
                  "trash_folders_section".tr,
                  controller.deletedFolders,
                  isFolder: true,
                );
              }
            } else if (hasNotes) {
              if (index == 0) {
                return _buildSection(
                  context,
                  "trash_notes_section".tr,
                  controller.deletedNotes,
                  isFolder: false,
                );
              }
            }
            return null;
          }, childCount: (hasFolders ? 1 : 0) + (hasNotes ? 1 : 0)),
        ),
      );
    });
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List items, {
    required bool isFolder,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        GlassCard(
          borderRadius: 28,
          padding: EdgeInsets.zero,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (isFolder)
                _buildFolderTile(context, items[i] as Folder)
              else
                _buildNoteTile(context, items[i] as Note),
              if (i < items.length - 1)
                Divider(
                  indent: 20,
                  endIndent: 20,
                  height: 1,
                  thickness: 0.5,
                  color: theme.dividerColor.withValues(alpha: 0.35),
                ),
            ],
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFolderTile(BuildContext context, Folder folder) {
    final theme = Theme.of(context);
    return SlidableNoteTile(
      onMove: () => controller.recoverItem(folderId: folder.id),
      onDelete: controller.canDeletePermanently
          ? () => controller.deleteItemPermanently(
              folderId: folder.id,
              name: folder.displayName,
            )
          : null,
      child: Obx(() {
        final isSelected = controller.selectedFolderIds.contains(folder.id);
        final isEditing = controller.isEditing.value;

        return TrashItemContextMenu(
          folder: folder,
          controller: controller,
          triggerBuilder: (context, openMenu) => CustomGlassListTile(
            standalone: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            onTap: isEditing
                ? () => controller.toggleSelectFolder(folder.id)
                : () => _showRestoreDialog(context, folder: folder),
            onLongPress: isEditing ? null : openMenu,
            leading: isEditing
                ? _buildSelectionIndicator(context, isSelected)
                : _buildGlassItemIcon(
                    context,
                    child: FolderGlyph(folder: folder, size: 24),
                  ),
            title: Text(
              folder.displayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                letterSpacing: -0.4,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "trash_folder_subtitle".trParams({
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
          ),
        );
      }),
    );
  }

  Widget _buildNoteTile(BuildContext context, Note note) {
    final theme = Theme.of(context);
    return SlidableNoteTile(
      onMove: () => controller.recoverItem(noteId: note.id),
      onDelete: controller.canDeletePermanently
          ? () => controller.deleteItemPermanently(
              noteId: note.id,
              name: note.title,
            )
          : null,
      child: Obx(() {
        final isSelected = controller.selectedNoteIds.contains(note.id);
        final isEditing = controller.isEditing.value;

        return TrashItemContextMenu(
          note: note,
          controller: controller,
          triggerBuilder: (context, openMenu) => CustomGlassListTile(
            standalone: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            onTap: isEditing
                ? () => controller.toggleSelectNote(note.id)
                : () => _showRestoreDialog(context, note: note),
            onLongPress: isEditing ? null : openMenu,
            leading: isEditing
                ? _buildSelectionIndicator(context, isSelected)
                : _buildGlassItemIcon(
                    context,
                    child: Icon(
                      CupertinoIcons.doc_text_fill,
                      size: 19,
                      color: theme.colorScheme.primary,
                    ),
                  ),
            title: Text(
              note.displayTitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                letterSpacing: -0.4,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "${DateFormatter.relative(note.updatedAt)}  ${NoteSnippet.of(note)}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                  fontSize: 13,
                ),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              size: 20,
            ),
          ),
        );
      }),
    );
  }

  // DELETED: _showItemContextMenu as it's now handled by TrashItemContextMenu

  void _showRestoreDialog(BuildContext context, {Note? note, Folder? folder}) {
    IOSConfirmationDialog.show(
      title: note != null
          ? "trash_restore_note_message".tr
          : "trash_restore_folder_message".tr,
      confirmLabel: "trash_restore".tr,
      isDestructive: false,
      onConfirm: () {
        if (note != null) {
          controller.recoverItem(noteId: note.id);
        } else if (folder != null) {
          controller.recoverItem(folderId: folder.id);
        }
      },
    );
  }

  Widget _buildSelectionIndicator(BuildContext context, bool isSelected) {
    final theme = Theme.of(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? theme.primaryColor : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? theme.primaryColor
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.surface, size: 14)
          : null,
    );
  }

  Widget _buildGlassItemIcon(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;

    return CustomGlassContainer(
      width: 40,
      height: 40,
      borderRadius: 11,
      blur: 12,
      opacity: 0.12,
      thickness: 6,
      refractiveIndex: 1.1,
      glassColor: scheme.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildEditBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (controller.canDeletePermanently) ...[
              Expanded(
                child: _actionButton(
                  context,
                  "trash_delete".tr,
                  color: Colors.redAccent,
                  onTap: controller.deletePermanentlySelectedItems,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: _actionButton(
                context,
                "trash_recover".tr,
                onTap: controller.recoverSelectedItems,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label, {
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return CustomGlassButton(
      onPressed: onTap,
      height: 48,
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      blur: 10,
      opacity: 0.15,
      thickness: 8,
      child: Text(
        label,
        style: TextStyle(
          color: color ?? theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
