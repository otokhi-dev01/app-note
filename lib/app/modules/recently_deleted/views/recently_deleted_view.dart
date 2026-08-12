import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/folder_model.dart';
import '../../../data/models/note_model.dart';
import '../../../routes/app_pages.dart';
import '../../../routes/note_navigation.dart';
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
        extendBodyBehindAppBar: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            _buildInfoSection(context),
            _buildDeletedItemsSection(context),
            const SliverToBoxAdapter(
              child: SizedBox(height: 112),
            ),
          ],
        ),
        bottomNavigationBar: Obx(
              () => controller.isEditing.value
              ? _buildEditBottomBar(context)
              : _buildSearchBottomBar(context),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      expandedHeight: 150,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      systemOverlayStyle: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leadingWidth: 72,
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
            padding: EdgeInsets.zero,
            icon: Icon(
              CupertinoIcons.chevron_left,
              color: theme.colorScheme.onSurface,
              size: 25,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Obx(
                () => controller.isEditing.value
                ? _buildDoneButton(context)
                : _buildEditButton(context),
          ),
        ),
      ],
      title: Text(
        'Recently Deleted',
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          14,
        ),
        title: Text(
          'Recently Deleted',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 29,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassContainer(
      height: 44,
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      showGlow: true,
      thickness: 8,
      opacity: 0.15,
      blur: 10,
      child: TextButton(
        onPressed: controller.toggleEditing,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Edit',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassContainer(
      width: 44,
      height: 44,
      shape: GlassShape.circle,
      showGlow: true,
      thickness: 8,
      opacity: 0.15,
      blur: 10,
      child: GestureDetector(
        onTap: controller.toggleEditing,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primaryColor,
            ),
            child: const Icon(
              CupertinoIcons.check_mark,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          14,
        ),
        child: Obx(
              () {
            final totalItems =
                controller.deletedNotes.length +
                    controller.deletedFolders.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _itemCountText(totalItems),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Deleted notes and folders are available here for 30 days. '
                      'You can recover them before they are permanently deleted.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15.5,
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeletedItemsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(
          () {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            child: Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            ),
          );
        }

        final totalItems =
            controller.deletedNotes.length +
                controller.deletedFolders.length;

        if (totalItems == 0) {
          return _buildEmptyState(context);
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20,
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHigh
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: theme.brightness == Brightness.dark
                    ? null
                    : [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.035,
                    ),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (
                    int i = 0;
                    i < controller.deletedFolders.length;
                    i++
                    ) ...[
                      _buildFolderTile(
                        context,
                        controller.deletedFolders[i],
                      ),
                      if (i <
                          controller.deletedFolders.length -
                              1 ||
                          controller.deletedNotes.isNotEmpty)
                        _buildDivider(
                          context,
                          hasLeading:
                          controller.isEditing.value,
                        ),
                    ],
                    for (
                    int i = 0;
                    i < controller.deletedNotes.length;
                    i++
                    ) ...[
                      _buildNoteTile(
                        context,
                        controller.deletedNotes[i],
                      ),
                      if (i <
                          controller.deletedNotes.length - 1)
                        _buildDivider(
                          context,
                          hasLeading:
                          controller.isEditing.value,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(
      BuildContext context, {
        bool hasLeading = false,
      }) {
    final theme = Theme.of(context);

    return Divider(
      height: 1,
      thickness: 0.5,
      indent: hasLeading ? 58 : 20,
      endIndent: 20,
      color: theme.dividerColor.withValues(
        alpha: 0.4,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 80,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.trash,
              size: 50,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.28),
            ),
            const SizedBox(height: 16),
            Text(
              'No Deleted Items',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Deleted notes and folders will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: controller.fetchDeletedItems,
              child: const Text(
                'Check for updates',
              ),
            ),
          ],
        ),
      ),
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
      onDelete: () => controller.deleteItemPermanently(
        folderId: folder.id,
        name: folder.name,
      ),
      child: Obx(
            () {
          final isEditing =
              controller.isEditing.value;

          final isSelected =
          controller.selectedFolderIds.contains(
            folder.id,
          );

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEditing
                  ? () => controller.toggleSelectFolder(
                folder.id,
              )
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    if (isEditing)
                      _buildSelectionIndicator(
                        context,
                        isSelected,
                      ),
                    Icon(
                      folder.icon,
                      color: theme.primaryColor,
                      size: 25,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: theme
                                .textTheme.titleMedium
                                ?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Folder',
                            style: theme
                                .textTheme.bodyMedium
                                ?.copyWith(
                              fontSize: 15,
                              color: theme.colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteTile(
      BuildContext context,
      NoteModel note,
      ) {
    final theme = Theme.of(context);

    final attachmentCount =
        note.content.whereType<AttachmentBlock>().length;

    return SlidableNoteTile(
      onMove: () => controller.recoverItem(
        noteId: note.id,
      ),
      onDelete: () => controller.deleteItemPermanently(
        noteId: note.id,
        name: note.title,
      ),
      child: Obx(
            () {
          final isEditing =
              controller.isEditing.value;

          final isSelected =
          controller.selectedNoteIds.contains(
            note.id,
          );

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEditing
                  ? () => controller.toggleSelectNote(
                note.id,
              )
                  : () => NoteNavigation.toDetail(note),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    if (isEditing)
                      _buildSelectionIndicator(
                        context,
                        isSelected,
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title.isEmpty
                                ? 'New Note'
                                : note.title,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: theme
                                .textTheme.titleMedium
                                ?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _formatDate(
                                  note.updatedAt,
                                ),
                                style: theme
                                    .textTheme.bodyMedium
                                    ?.copyWith(
                                  fontSize: 15,
                                  color: theme.colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  attachmentCount > 0
                                      ? '$attachmentCount attachment${attachmentCount == 1 ? '' : 's'}'
                                      : _getContentSnippet(
                                    note,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: theme
                                      .textTheme.bodyMedium
                                      ?.copyWith(
                                    fontSize: 15,
                                    color: theme.colorScheme
                                        .onSurfaceVariant
                                        .withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
      margin: const EdgeInsets.only(
        right: 12,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? theme.primaryColor
            : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? theme.primaryColor
              : theme.colorScheme.onSurfaceVariant
              .withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(
        CupertinoIcons.check_mark,
        color: Colors.white,
        size: 14,
      )
          : null,
    );
  }

  Widget _buildSearchBottomBar(
      BuildContext context,
      ) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          12,
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.toNamed(
                  Routes.SEARCH,
                ),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                    BorderRadius.circular(25),
                    boxShadow:
                    theme.brightness == Brightness.dark
                        ? null
                        : [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        color: theme
                            .colorScheme.onSurfaceVariant,
                        size: 21,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Search',
                          style: TextStyle(
                            color: theme.colorScheme
                                .onSurfaceVariant,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.mic,
                        color: theme
                            .colorScheme.onSurfaceVariant,
                        size: 21,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            LiquidGlassContainer(
              width: 50,
              height: 50,
              shape: GlassShape.circle,
              showGlow: true,
              thickness: 10,
              refractiveIndex: 1.3,
              opacity: 0.15,
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  CupertinoIcons.square_arrow_up,
                  color: theme.colorScheme.onSurface,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditBottomBar(
      BuildContext context,
      ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          12,
        ),
        child: Obx(
              () {
            final hasSelection =
                controller.selectedNoteIds.isNotEmpty ||
                    controller.selectedFolderIds.isNotEmpty;

            return Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                _actionButton(
                  context,
                  hasSelection
                      ? 'Recover'
                      : 'Recover All',
                  onTap:
                  controller.recoverSelectedItems,
                ),
                _actionButton(
                  context,
                  hasSelection
                      ? 'Delete'
                      : 'Delete All',
                  color: CupertinoColors.systemRed,
                  onTap: controller
                      .deletePermanentlySelectedItems,
                ),
              ],
            );
          },
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
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        thickness: 6,
        showGlow: true,
        opacity: 0.15,
        child: Text(
          label,
          style: TextStyle(
            color:
            color ?? theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _itemCountText(int count) {
    if (count == 1) {
      return '1 Item';
    }

    return '$count Items';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final now = DateTime.now();

    final isToday =
        date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

    if (isToday) {
      return DateFormat('HH:mm').format(date);
    }

    return DateFormat('M/d/yy').format(date);
  }

  String _getContentSnippet(NoteModel note) {
    final textBlock =
    note.content.firstWhereOrNull(
          (block) => block is TextBlock,
    )
    as TextBlock?;

    if (textBlock == null) {
      return '';
    }

    return textBlock.text
        .trim()
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
  }
}