import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/main/presentation/widgets/app_liquid_background_widget.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../main/presentation/controller/main_navigation_controller.dart';
import '../../../main/presentation/widgets/main_tab_header_widget.dart';
import '../../../notes/presentation/controllers/home_controller.dart';
import '../../domain/entities/folder_entity.dart';

class FolderListView
    extends GetView<HomeController> {
  const FolderListView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: AppLiquidBackgroundWidget(),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  0,
                ),
                child: Obx(
                      () {
                    final int folderCount =
                        controller
                            .folders.length;

                    final int deletedCount =
                        controller
                            .deletedFolders
                            .length;

                    return MainTabHeader(
                      title: 'Folders',
                      subtitle:
                      '$folderCount active '
                          '${folderCount == 1 ? 'folder' : 'folders'}',
                      trailing:
                      MainTabHeaderAction(
                        tooltip:
                        'Recently Deleted',
                        icon: deletedCount > 0
                            ? CupertinoIcons
                            .delete_solid
                            : CupertinoIcons
                            .delete,
                        onPressed: () {
                          _openRecentlyDeleted();
                        },
                      ),
                      onRefresh:
                      controller.loadFolders,
                      onAdd: () {
                        _openCreateFolder();
                      },
                      addIcon: Icons
                          .create_new_folder_outlined,
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
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
    );
  }

  Widget _buildContent(
      BuildContext context,
      ) {
    final List<FolderEntity>
    folderSnapshot =
    List<FolderEntity>.unmodifiable(
      controller.folders.toList(),
    );

    if (controller
        .isFoldersLoading.value &&
        folderSnapshot.isEmpty) {
      return const _FolderLoadingState();
    }

    if (controller.hasFolderError &&
        folderSnapshot.isEmpty) {
      return _FolderErrorState(
        message: controller
            .folderErrorMessage.value,
        onRetry:
        controller.loadFolders,
      );
    }

    final int totalNotes =
    controller.notes.isNotEmpty
        ? controller.notes.length
        : folderSnapshot.fold<int>(
      0,
          (
          int total,
          FolderEntity folder,
          ) {
        return total +
            folder.noteCount;
      },
    );

    return RefreshIndicator.adaptive(
      onRefresh:
      controller.loadFolders,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
        padding:
        const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          120,
        ),
        children: <Widget>[
          _FolderCard(
            title: 'All Notes',
            subtitle:
            '$totalNotes '
                '${totalNotes == 1 ? 'note' : 'notes'}',
            noteCount: totalNotes,
            color: Theme.of(context)
                .colorScheme.primary,
            icon: Icons.notes_rounded,
            selected: controller
                .selectedFolderId
                .value ==
                null,
            onTap: () {
              controller
                  .selectAllNotes();

              _openNoteTab();
            },
          ),
          const SizedBox(height: 12),
          if (folderSnapshot.isEmpty)
            _EmptyFolderState(
              onCreate:
              _openCreateFolder,
              onOpenDeleted:
              _openRecentlyDeleted,
            )
          else
            ...folderSnapshot.map(
                  (FolderEntity folder) {
                final Color folderColor =
                _parseFolderColor(
                  folder.colorValue,
                  Theme.of(context)
                      .colorScheme
                      .primary,
                );

                return Padding(
                  key: ValueKey<int>(
                    folder.id,
                  ),
                  padding:
                  const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _FolderCard(
                    title:
                    folder.name
                        .trim()
                        .isEmpty
                        ? 'Unnamed Folder'
                        : folder.name,
                    subtitle:
                    '${folder.noteCount} '
                        '${folder.noteCount == 1 ? 'note' : 'notes'}',
                    noteCount:
                    folder.noteCount,
                    color: folderColor,
                    icon: _folderIcon(
                      folder.iconName,
                    ),
                    selected: controller
                        .selectedFolderId
                        .value ==
                        folder.id,
                    onTap: () {
                      controller
                          .selectFolder(
                        folder.id,
                      );

                      _openNoteTab();
                    },
                    onMore: () {
                      _showFolderActions(
                        context,
                        folder,
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void>
  _openRecentlyDeleted() async {
    await Get.toNamed(
      AppRoutes
          .recentlyDeletedFolders,
    );

    await controller.loadFolders();
  }

  Future<void>
  _openCreateFolder() async {
    final dynamic result =
    await Get.toNamed(
      AppRoutes.createFolder,
    );

    if (result == true) {
      await controller.loadFolders();
    }
  }

  void _openNoteTab() {
    if (Get.isRegistered<
        MainNavigationController>()) {
      Get.find<
          MainNavigationController>()
          .changeTab(1);
    }
  }

  Future<void> _showFolderActions(
      BuildContext context,
      FolderEntity folder,
      ) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (
          BuildContext sheetContext,
          ) {
        return CupertinoActionSheet(
          title: Text(
            folder.name
                .trim()
                .isEmpty
                ? 'Unnamed Folder'
                : folder.name,
          ),
          message: const Text(
            'Choose an action for this folder.',
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(
                  sheetContext,
                ).pop();

                _showRenameDialog(
                  context,
                  folder,
                );
              },
              child: const Text(
                'Rename Folder',
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(
                  sheetContext,
                ).pop();

                _confirmDelete(
                  context,
                  folder,
                );
              },
              child: const Text(
                'Move to Recently Deleted',
              ),
            ),
          ],
          cancelButton:
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(
                sheetContext,
              ).pop();
            },
            child: const Text(
              'Cancel',
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRenameDialog(
      BuildContext context,
      FolderEntity folder,
      ) async {
    final TextEditingController
    textController =
    TextEditingController(
      text: folder.name,
    );

    final String? newName =
    await showCupertinoDialog<
        String>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return CupertinoAlertDialog(
          title: const Text(
            'Rename Folder',
          ),
          content: Padding(
            padding:
            const EdgeInsets.only(
              top: 14,
            ),
            child: CupertinoTextField(
              controller:
              textController,
              autofocus: true,
              placeholder:
              'Folder name',
              textInputAction:
              TextInputAction.done,
              onSubmitted: (
                  String value,
                  ) {
                final String name =
                value.trim();

                if (name.isNotEmpty) {
                  Navigator.of(
                    dialogContext,
                  ).pop(name);
                }
              },
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Cancel',
              ),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final String name =
                textController.text
                    .trim();

                if (name.isNotEmpty) {
                  Navigator.of(
                    dialogContext,
                  ).pop(name);
                }
              },
              child: const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (newName == null ||
        newName.trim().isEmpty) {
      return;
    }

    await controller.updateFolder(
      folder: folder,
      name: newName,
    );
  }

  Future<void> _confirmDelete(
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
            'Delete Folder?',
          ),
          content: Text(
            '"$folderName" will be moved '
                'to Recently Deleted. You can '
                'restore it later.',
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
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller
        .deleteOrRestoreFolder(
      folderId: folder.id,
      isDelete: true,
    );
  }
}

class _FolderCard
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final int noteCount;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  const _FolderCard({
    required this.title,
    required this.subtitle,
    required this.noteCount,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.onMore,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(24),
        child: Container(
          padding:
          const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(
              0xFF1B1D22,
            )
                : Colors.white,
            borderRadius:
            BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? color.withValues(
                alpha: 0.55,
              )
                  : colorScheme
                  .outlineVariant
                  .withValues(
                alpha: isDark
                    ? 0.20
                    : 0.36,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: isDark
                      ? 0.14
                      : 0.045,
                ),
                blurRadius: 22,
                offset:
                const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color
                      .withValues(
                    alpha: 0.13,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    17,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                constraints:
                const BoxConstraints(
                  minWidth: 34,
                ),
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  noteCount.toString(),
                  textAlign:
                  TextAlign.center,
                  style: theme
                      .textTheme.labelMedium
                      ?.copyWith(
                    color: color,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
              if (onMore != null) ...<
                  Widget>[
                const SizedBox(width: 4),
                CupertinoButton(
                  padding:
                  EdgeInsets.zero,
                  onPressed: onMore,
                  child: Icon(
                    Icons
                        .more_horiz_rounded,
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ] else ...<Widget>[
                const SizedBox(width: 8),
                Icon(
                  Icons
                      .chevron_right_rounded,
                  color: colorScheme
                      .onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFolderState
    extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onOpenDeleted;

  const _EmptyFolderState({
    required this.onCreate,
    required this.onOpenDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 65,
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons
                .create_new_folder_outlined,
            size: 58,
            color:
            colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Folders Yet',
            style: theme
                .textTheme.titleLarge
                ?.copyWith(
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a folder to organize '
                'your notes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme
                  .onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Create Folder',
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onOpenDeleted,
            icon: const Icon(
              CupertinoIcons.delete,
            ),
            label: const Text(
              'Recently Deleted',
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderLoadingState
    extends StatelessWidget {
  const _FolderLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child:
      CircularProgressIndicator
          .adaptive(),
    );
  }
}

class _FolderErrorState
    extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FolderErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off_outlined,
              size: 54,
              color: Theme.of(context)
                  .colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Folders Are Unavailable',
              style: Theme.of(context)
                  .textTheme.titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _folderIcon(
    String value,
    ) {
  switch (
  value.trim().toLowerCase()) {
    case 'work':
      return Icons.work_rounded;

    case 'school':
      return Icons.school_rounded;

    case 'personal':
      return Icons.person_rounded;

    case 'favorite':
      return Icons.favorite_rounded;

    case 'travel':
      return Icons.flight_rounded;

    default:
      return Icons.folder_rounded;
  }
}

Color _parseFolderColor(
    String rawValue,
    Color fallback,
    ) {
  final String value =
  rawValue.trim();

  if (value.isEmpty ||
      value.toLowerCase() ==
          'string') {
    return fallback;
  }

  try {
    String hex = value
        .replaceAll('#', '')
        .replaceAll('0x', '');

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return fallback;
    }

    return Color(
      int.parse(
        hex,
        radix: 16,
      ),
    );
  } catch (_) {
    return fallback;
  }
}