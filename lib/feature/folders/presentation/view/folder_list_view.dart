import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/main/presentation/widgets/app_liquid_background_widget.dart';
import 'package:note_app/feature/main/presentation/widgets/main_tab_header_widget.dart';
import '../../../main/presentation/controller/main_navigation_controller.dart';
import '../../../notes/presentation/controllers/home_controller.dart';
import '../../../profile/presentation/views/profile_view.dart';
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
                padding: const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  0,
                ),
                child: Obx(
                      () => MainTabHeaderWidget(
                    title: 'Folders'.tr,
                    subtitle:
                    '${controller.folders.length} folders',
                    onRefresh:
                    controller.loadFolders,
                    onAdd: () {
                      _showCreateFolderDialog(
                        context,
                      );
                    },
                    addIcon: Icons
                        .create_new_folder_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Obx(
                      () => _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (controller.isFoldersLoading.value &&
        controller.folders.isEmpty) {
      return const _FolderLoadingState();
    }

    if (controller.hasFolderError &&
        controller.folders.isEmpty) {
      return _FolderErrorState(
        message:
        controller.folderErrorMessage.value,
        onRetry: controller.loadFolders,
      );
    }

    final List<FolderEntity> folders =
        controller.folders;

    final int totalNotes =
    controller.notes.isNotEmpty
        ? controller.notes.length
        : folders.fold<int>(
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
      onRefresh: controller.loadFolders,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          120,
        ),
        children: <Widget>[
          _FolderCard(
            title: 'All Notes',
            subtitle: 'View notes from every folder',
            noteCount: totalNotes,
            color: Theme.of(context)
                .colorScheme
                .primary,
            icon: Icons.notes_rounded,
            selected:
            controller.selectedFolderId.value ==
                null,
            onTap: () {
              controller.selectAllNotes();

              Get.find<
                  MainNavigationController>()
                  .changeTab(1);
            },
          ),
          const SizedBox(height: 12),
          if (folders.isEmpty)
            _EmptyFolderState(
              onCreate: () {
                _showCreateFolderDialog(context);
              },
            )
          else
            ...folders.map(
                  (FolderEntity folder) {
                final Color folderColor =
                _parseFolderColor(
                  folder.colorValue,
                  Theme.of(context)
                      .colorScheme
                      .primary,
                );

                return Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _FolderCard(
                    title:
                    folder.name.trim().isEmpty
                        ? 'Unnamed Folder'
                        : folder.name,
                    subtitle:
                    '${folder.noteCount} ${folder.noteCount == 1 ? 'note' : 'notes'}',
                    noteCount:
                    folder.noteCount,
                    color: folderColor,
                    icon:
                    Icons.folder_rounded,
                    selected: controller
                        .selectedFolderId
                        .value ==
                        folder.id,
                    onTap: () {
                      controller
                          .selectFolder(folder.id);

                      Get.find<
                          MainNavigationController>()
                          .changeTab(1);
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

  Future<void> _showCreateFolderDialog(
      BuildContext context,
      ) async {
    String folderName = '';

    final String? result =
    await showCupertinoDialog<String>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return CupertinoAlertDialog(
          title: const Text('New Folder'),
          content: Padding(
            padding:
            const EdgeInsets.only(top: 14),
            child: CupertinoTextField(
              autofocus: true,
              placeholder: 'Folder name',
              textInputAction:
              TextInputAction.done,
              onChanged: (String value) {
                folderName = value;
              },
              onSubmitted: (String value) {
                final String name =
                value.trim();

                if (name.isNotEmpty) {
                  Navigator.of(dialogContext)
                      .pop(name);
                }
              },
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final String name =
                folderName.trim();

                if (name.isNotEmpty) {
                  Navigator.of(dialogContext)
                      .pop(name);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result == null ||
        result.trim().isEmpty) {
      return;
    }

    await controller.createFolder(
      name: result,
    );
  }

  Future<void> _showRenameFolderDialog(
      BuildContext context,
      FolderEntity folder,
      ) async {
    final TextEditingController textController =
    TextEditingController(
      text: folder.name,
    );

    final String? result =
    await showCupertinoDialog<String>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return CupertinoAlertDialog(
          title: const Text('Rename Folder'),
          content: Padding(
            padding:
            const EdgeInsets.only(top: 14),
            child: CupertinoTextField(
              controller: textController,
              autofocus: true,
              placeholder: 'Folder name',
              textInputAction:
              TextInputAction.done,
              onSubmitted: (String value) {
                final String name =
                value.trim();

                if (name.isNotEmpty) {
                  Navigator.of(dialogContext)
                      .pop(name);
                }
              },
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final String name =
                textController.text.trim();

                if (name.isNotEmpty) {
                  Navigator.of(dialogContext)
                      .pop(name);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (result == null ||
        result.trim().isEmpty) {
      return;
    }

    await controller.updateFolder(
      folder: folder,
      name: result,
    );
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
            folder.name.trim().isEmpty
                ? 'Unnamed Folder'
                : folder.name,
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _showRenameFolderDialog(
                  context,
                  folder,
                );
              },
              child: const Text('Rename Folder'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _confirmDeleteFolder(
                  context,
                  folder,
                );
              },
              child: const Text('Delete Folder'),
            ),
          ],
          cancelButton:
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteFolder(
      BuildContext context,
      FolderEntity folder,
      ) async {
    final bool? confirmed =
    await showCupertinoDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return CupertinoAlertDialog(
          title: const Text('Delete Folder?'),
          content: Text(
            'Delete "${folder.name}"? '
                'Notes inside this folder may also be affected.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.deleteOrRestoreFolder(
      folderId: folder.id,
      isDelete: true,
    );
  }
}

class _FolderCard extends StatelessWidget {
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1B1D22)
                : Colors.white,
            borderRadius:
            BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : colorScheme.outlineVariant
                  .withValues(
                alpha:
                isDark ? 0.20 : 0.36,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(
                  alpha:
                  isDark ? 0.14 : 0.045,
                ),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                  color.withValues(alpha: 0.13),
                  borderRadius:
                  BorderRadius.circular(17),
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
                  CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: theme
                          .textTheme.titleMedium
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: theme
                          .textTheme.bodySmall
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
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                  color.withValues(alpha: 0.10),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Text(
                  noteCount.toString(),
                  textAlign: TextAlign.center,
                  style: theme
                      .textTheme.labelMedium
                      ?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onMore != null) ...<Widget>[
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onMore,
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ] else ...<Widget>[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
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

  const _EmptyFolderState({
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.create_new_folder_outlined,
            size: 58,
            color:
            Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No folders yet',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a folder to organize your notes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Folder'),
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
      child: CircularProgressIndicator.adaptive(),
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
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off_outlined,
              size: 54,
              color:
              Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Folders are unavailable',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _parseFolderColor(
    String rawValue,
    Color fallback,
    ) {
  final String value = rawValue.trim();

  if (value.isEmpty ||
      value.toLowerCase() == 'string') {
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
      int.parse(hex, radix: 16),
    );
  } catch (_) {
    return fallback;
  }
}