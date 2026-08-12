import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/folder_model.dart';
import '../../../data/models/note_model.dart';
import '../../../routes/note_navigation.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/recently_deleted_controller.dart';
import '../widgets/slidable_note_tile.dart';

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
              _buildTitleSection(context),
              _buildDeletedItemsList(context),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
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

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      expandedHeight: 140,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      systemOverlayStyle: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final double percentage =
              (constraints.maxHeight - kToolbarHeight) /
                  (140.0 - kToolbarHeight);

          final opacity =
          (1.0 - percentage).clamp(0.0, 1.0);

          return Opacity(
            opacity: opacity > 0.8 ? 1.0 : 0.0,
            child: Text(
              'Recently Deleted',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          );
        },
      ),
      leading: Center(
        child: LiquidGlassContainer(
          width: 44,
          height: 44,
          shape: GlassShape.circle,
          showGlow: true,
          thickness: 8,
          refractiveIndex: 1.1,
          opacity: 0.15,
          blur: 10,
          child: IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              CupertinoIcons.chevron_left,
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      leadingWidth: 70,
      actions: [
        Padding(
          padding: const EdgeInsets.only(
            right: 16,
          ),
          child: Obx(
                () => controller.isEditing.value
                ? LiquidGlassContainer(
              width: 44,
              height: 44,
              shape: GlassShape.circle,
              showGlow: true,
              thickness: 8,
              opacity: 0.15,
              blur: 10,
              child: GestureDetector(
                onTap: controller.toggleEditing,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            )
                : LiquidGlassContainer(
              height: 36,
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              showGlow: true,
              thickness: 8,
              opacity: 0.15,
              blur: 10,
              child: TextButton(
                onPressed:
                controller.toggleEditing,
                style: TextButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize:
                  MaterialTapTargetSize
                      .shrinkWrap,
                ),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    color: theme
                        .colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding:
        const EdgeInsets.fromLTRB(
          20,
          0,
          16,
          12,
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final double percentage =
                (constraints.maxHeight -
                    kToolbarHeight) /
                    (140.0 - kToolbarHeight);

            return Opacity(
              opacity:
              percentage.clamp(0.0, 1.0),
              child: Text(
                'Recently Deleted',
                style: theme
                    .textTheme.headlineLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitleSection(
      BuildContext context,
      ) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16,
        ),
        child: Obx(
              () {
            final noteCount =
                controller.deletedNotes.length;

            final folderCount =
                controller.deletedFolders.length;

            final totalItems =
                noteCount + folderCount;

            return Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalItems ${totalItems == 1 ? 'Item' : 'Items'}',
                  style: theme
                      .textTheme.bodyMedium
                      ?.copyWith(
                    color: theme.colorScheme
                        .onSurfaceVariant
                        .withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'Notes and folders are permanently removed after 30 days. '
                      'You can restore them before they are deleted.',
                  style: theme
                      .textTheme.bodySmall
                      ?.copyWith(
                    color: theme.colorScheme
                        .onSurfaceVariant
                        .withValues(
                      alpha: 0.5,
                    ),
                    height: 1.3,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeletedItemsList(
      BuildContext context,
      ) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.folderPink,
            ),
          ),
        );
      }

      final totalItems =
          controller.deletedNotes.length +
              controller.deletedFolders.length;

      if (totalItems == 0) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.trash,
                  size: 60,
                  color: Colors.grey.withValues(
                    alpha: 0.3,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  'No Deleted Items',
                  style: theme
                      .textTheme.titleMedium
                      ?.copyWith(
                    color: theme.colorScheme
                        .onSurfaceVariant
                        .withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        sliver: SliverList(
          delegate: SliverChildListDelegate(
            [
              if (controller
                  .deletedFolders.isNotEmpty) ...[
                _buildSection(
                  context,
                  'Folders',
                  controller.deletedFolders,
                  isFolder: true,
                ),
                const SizedBox(
                  height: 24,
                ),
              ],
              if (controller
                  .deletedNotes.isNotEmpty)
                _buildSection(
                  context,
                  'Notes',
                  controller.deletedNotes,
                  isFolder: false,
                ),
            ],
          ),
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
    final isDark =
        theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 12,
            top: 16,
            bottom: 8,
          ),
          child: Text(
            title,
            style: theme
                .textTheme.titleMedium
                ?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: theme
                  .colorScheme.onSurface
                  .withValues(
                alpha: 0.8,
              ),
            ),
          ),
        ),

        // UPDATED IOS STYLE PARENT CONTAINER
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius:
            BorderRadius.circular(28),
            border: isDark
                ? Border.all(
              color: Colors.white.withValues(
                alpha: 0.04,
              ),
              width: 0.5,
            )
                : null,
            boxShadow: isDark
                ? null
                : [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.035,
                ),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(
                  0,
                  7,
                ),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(28),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                for (
                int i = 0;
                i < items.length;
                i++
                ) ...[
                  if (isFolder)
                    _buildFolderTile(
                      context,
                      items[i] as FolderModel,
                    )
                  else
                    _buildNoteTile(
                      context,
                      items[i] as NoteModel,
                    ),
                  if (i < items.length - 1)
                    Divider(
                      indent: 20,
                      endIndent: 20,
                      height: 1,
                      thickness: 0.5,
                      color: theme.dividerColor
                          .withValues(
                        alpha: 0.35,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderTile(
      BuildContext context,
      FolderModel folder,
      ) {
    final theme = Theme.of(context);

    return SlidableNoteTile(
      onMove: () => controller.recoverItem(
        folderId: folder.id,
      ),
      onDelete: () =>
          controller.deleteItemPermanently(
            folderId: folder.id,
            name: folder.name,
          ),
      child: Obx(() {
        final isSelected = controller
            .selectedFolderIds
            .contains(folder.id);

        final isEditing =
            controller.isEditing.value;

        return ListTile(
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          onTap: isEditing
              ? () =>
              controller.toggleSelectFolder(
                folder.id,
              )
              : null,
          leading: isEditing
              ? _buildSelectionIndicator(
            context,
            isSelected,
          )
              : Icon(
            folder.icon,
            color:
            AppTheme.folderPink,
            size: 28,
          ),
          title: Text(
            folder.name,
            style:
            theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: -0.4,
            ),
          ),
          subtitle: Padding(
            padding:
            const EdgeInsets.only(
              top: 2,
            ),
            child: Text(
              'Folder  •  ${folder.noteCount} notes',
              style: theme
                  .textTheme.bodyMedium
                  ?.copyWith(
                color: theme.colorScheme
                    .onSurfaceVariant
                    .withValues(
                  alpha: 0.6,
                ),
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNoteTile(
      BuildContext context,
      NoteModel note,
      ) {
    final theme = Theme.of(context);

    final attachmentCount =
        note.attachmentCount;

    return SlidableNoteTile(
      onMove: () => controller.recoverItem(
        noteId: note.id,
      ),
      onDelete: () =>
          controller.deleteItemPermanently(
            noteId: note.id,
            name: note.title,
          ),
      child: Obx(() {
        final isSelected = controller
            .selectedNoteIds
            .contains(note.id);

        final isEditing =
            controller.isEditing.value;

        return ListTile(
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          onTap: isEditing
              ? () =>
              controller.toggleSelectNote(
                note.id,
              )
              : () =>
              NoteNavigation.toDetail(
                note,
              ),
          leading: isEditing
              ? _buildSelectionIndicator(
            context,
            isSelected,
          )
              : null,
          title: Text(
            note.displayTitle,
            style:
            theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: -0.4,
            ),
          ),
          subtitle: Padding(
            padding:
            const EdgeInsets.only(
              top: 2,
            ),
            child: Text(
              '${_formatDate(note.updatedAt)}  '
                  '${attachmentCount > 0 ? '$attachmentCount attachments' : _getContentSnippet(note)}',
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: theme
                  .textTheme.bodyMedium
                  ?.copyWith(
                color: theme.colorScheme
                    .onSurfaceVariant
                    .withValues(
                  alpha: 0.6,
                ),
                fontSize: 13,
              ),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme
                .onSurfaceVariant
                .withValues(
              alpha: 0.2,
            ),
            size: 20,
          ),
        );
      }),
    );
  }

  Widget _buildSelectionIndicator(
      BuildContext context,
      bool isSelected,
      ) {
    final theme = Theme.of(context);

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? theme.primaryColor
            : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? theme.primaryColor
              : theme.colorScheme
              .onSurfaceVariant
              .withValues(
            alpha: 0.5,
          ),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Icon(
        Icons.check,
        color:
        theme.colorScheme.surface,
        size: 14,
      )
          : null,
    );
  }

  Widget _buildEditBottomBar(
      BuildContext context,
      ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            _actionButton(
              context,
              'Delete',
              color: Colors.redAccent,
              onTap: controller
                  .deletePermanentlySelectedItems,
            ),
            _actionButton(
              context,
              'Recover',
              onTap:
              controller.recoverSelectedItems,
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

    return GestureDetector(
      onTap: onTap,
      child: LiquidGlassContainer(
        borderRadius: 25,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        thickness: 6,
        showGlow: true,
        opacity: 0.15,
        child: Text(
          label,
          style: TextStyle(
            color: color ??
                theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatDate(
      DateTime? date,
      ) {
    if (date == null) {
      return '';
    }

    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat('HH:mm').format(
        date,
      );
    }

    return DateFormat('M/d/yy').format(
      date,
    );
  }

  String _getContentSnippet(
      NoteModel note,
      ) {
    if (note.content.isEmpty) {
      return '';
    }

    final textBlock =
    note.content.firstWhereOrNull(
          (b) => b is TextBlock,
    )
    as TextBlock?;

    if (textBlock == null) {
      return '';
    }

    return NoteModel.extractPlainText(
      textBlock.text,
    );
  }
}