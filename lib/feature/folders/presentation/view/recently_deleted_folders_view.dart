import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../main/presentation/widgets/app_liquid_background_widget.dart';
import '../../domain/entities/folder_entity.dart';
import '../controller/recently_deleted_folders_controller.dart';

class RecentlyDeletedFoldersView extends GetView<
    RecentlyDeletedFoldersController> {
  const RecentlyDeletedFoldersView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: AppLiquidBackgroundWidget(),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                const _RecentlyDeletedHeader(),
                Expanded(
                  child: Obx(
                        () => _buildContent(
                      context,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      ) {
    final List<FolderEntity>
    folderSnapshot =
    List<FolderEntity>.unmodifiable(
      controller.deletedFolders,
    );

    if (controller.isRefreshing.value &&
        folderSnapshot.isEmpty) {
      return const _LoadingState();
    }

    final String error =
    controller.errorMessage.value.trim();

    if (error.isNotEmpty &&
        folderSnapshot.isEmpty) {
      return _ErrorState(
        message: error,
        onRetry: controller.refreshFolders,
      );
    }

    if (folderSnapshot.isEmpty) {
      return _EmptyState(
        onRefresh:
        controller.refreshFolders,
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh:
      controller.refreshFolders,
      child: ListView.separated(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          40,
        ),
        itemCount: folderSnapshot.length,
        separatorBuilder: (
            BuildContext context,
            int index,
            ) {
          return const SizedBox(
            height: 12,
          );
        },
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          if (index < 0 ||
              index >=
                  folderSnapshot.length) {
            return const SizedBox.shrink();
          }

          final FolderEntity folder =
          folderSnapshot[index];

          return Obx(
                () => _DeletedFolderCard(
              key: ValueKey<int>(
                folder.id,
              ),
              folder: folder,
              deletedDateText:
              controller.deletedDateText(
                folder,
              ),
              isRestoring:
              controller.isRestoring(
                folder.id,
              ),
              onRestore: () {
                _confirmRestore(
                  context,
                  folder,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRestore(
      BuildContext context,
      FolderEntity folder,
      ) async {
    final String folderName =
    folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();

    final bool? confirmed =
    await showCupertinoDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return CupertinoAlertDialog(
          title: const Text(
            'Restore Folder?',
          ),
          content: Text(
            '"$folderName" will be moved '
                'back to your active folder list.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Restore',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.restoreFolder(
      folder,
    );
  }
}

class _RecentlyDeletedHeader extends GetView<
    RecentlyDeletedFoldersController> {
  const _RecentlyDeletedHeader();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8,
        6,
        10,
        10,
      ),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            padding:
            const EdgeInsets.all(8),
            onPressed: () {
              Get.back<void>();
            },
            child: Icon(
              CupertinoIcons.back,
              color:
              colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Recently Deleted',
                  style: theme
                      .textTheme.titleLarge
                      ?.copyWith(
                    color:
                    colorScheme.onSurface,
                    fontWeight:
                    FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Obx(
                      () {
                    final int count =
                        controller
                            .deletedFolderCount;

                    return Text(
                      '$count deleted '
                          '${count == 1 ? 'folder' : 'folders'}',
                      style: theme
                          .textTheme.bodySmall
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Obx(
                () => CupertinoButton(
              padding:
              const EdgeInsets.all(10),
              onPressed: controller
                  .isRefreshing.value
                  ? null
                  : () {
                controller
                    .refreshFolders();
              },
              child: controller
                  .isRefreshing.value
                  ? const CupertinoActivityIndicator()
                  : Icon(
                CupertinoIcons.refresh,
                color:
                colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletedFolderCard
    extends StatelessWidget {
  final FolderEntity folder;
  final String deletedDateText;
  final bool isRestoring;
  final VoidCallback onRestore;

  const _DeletedFolderCard({
    super.key,
    required this.folder,
    required this.deletedDateText,
    required this.isRestoring,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness ==
            Brightness.dark;

    final String folderName =
    folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius:
        BorderRadius.circular(24),
        border: Border.all(
          color:
          colorScheme.outlineVariant
              .withValues(
            alpha:
            isDark ? 0.18 : 0.35,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha:
              isDark ? 0.14 : 0.045,
            ),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colorScheme.error
                  .withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(18),
            ),
            child: Icon(
              CupertinoIcons
                  .folder_fill,
              size: 27,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  folderName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: theme
                      .textTheme.titleMedium
                      ?.copyWith(
                    color:
                    colorScheme.onSurface,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${folder.noteCount} '
                      '${folder.noteCount == 1 ? 'note' : 'notes'}',
                  style: theme
                      .textTheme.bodySmall
                      ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  deletedDateText,
                  style: theme
                      .textTheme.bodySmall
                      ?.copyWith(
                    color:
                    colorScheme.error,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed:
            isRestoring
                ? null
                : onRestore,
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 180,
              ),
              height: 42,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 13,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary
                    .withValues(
                  alpha: 0.11,
                ),
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary
                      .withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize:
                MainAxisSize.min,
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: <Widget>[
                  if (isRestoring)
                    const CupertinoActivityIndicator()
                  else ...<Widget>[
                    Icon(
                      CupertinoIcons
                          .arrow_counterclockwise,
                      size: 17,
                      color:
                      colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Restore',
                      style: theme
                          .textTheme.labelLarge
                          ?.copyWith(
                        color: colorScheme
                            .primary,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState
    extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CupertinoActivityIndicator(
        radius: 15,
      ),
    );
  }
}

class _EmptyState
    extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  30,
                  30,
                  30,
                  100,
                ),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 92,
                      height: 92,
                      decoration:
                      BoxDecoration(
                        shape:
                        BoxShape.circle,
                        color: colorScheme
                            .primary
                            .withValues(
                          alpha: 0.10,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.delete,
                        size: 42,
                        color:
                        colorScheme.primary,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      'No Deleted Folders',
                      textAlign:
                      TextAlign.center,
                      style: theme
                          .textTheme.titleLarge
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Folders you delete will '
                          'appear here so you can '
                          'restore them later.',
                      textAlign:
                      TextAlign.center,
                      style: theme
                          .textTheme.bodyMedium
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    return RefreshIndicator.adaptive(
      onRefresh: onRetry,
      child: CustomScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding:
                const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      CupertinoIcons
                          .exclamationmark_triangle,
                      size: 52,
                      color:
                      colorScheme.error,
                    ),
                    const SizedBox(
                      height: 17,
                    ),
                    Text(
                      'Unable to Load Deleted Folders',
                      textAlign:
                      TextAlign.center,
                      style: theme
                          .textTheme.titleLarge
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      message,
                      textAlign:
                      TextAlign.center,
                      style: theme
                          .textTheme.bodyMedium
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        onRetry();
                      },
                      icon: const Icon(
                        CupertinoIcons.refresh,
                      ),
                      label: const Text(
                        'Try Again',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}