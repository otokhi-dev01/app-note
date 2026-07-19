import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/main/presentation/widgets/app_liquid_background_widget.dart';
import 'package:note_app/feature/main/presentation/widgets/main_tab_header_widget.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../domain/entities/note_entity.dart';
import '../controllers/home_controller.dart';

class NoteListView extends GetView<HomeController> {
  const NoteListView({
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
                      () {
                    final int noteCount =
                        controller.visibleNotes.length;

                    return MainTabHeaderWidget(
                      title: controller.selectedFolderName,
                      subtitle:
                      '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
                      onRefresh: () {
                        controller.loadAll();
                      },
                      onAdd: () {
                        _openCreateNoteScreen();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              /*
               * Important:
               *
               * Do not pass controller.folders directly to a lazy
               * ListView because it is an RxList and can change while
               * Flutter is building its children.
               */
              Obx(
                    () {
                  final List<FolderEntity> folderSnapshot =
                  List<FolderEntity>.unmodifiable(
                    controller.folders.toList(),
                  );

                  return _FolderFilterStrip(
                    folders: folderSnapshot,
                    selectedFolderId:
                    controller.selectedFolderId.value,
                    onSelectAll:
                    controller.selectAllNotes,
                    onSelectFolder:
                    controller.selectFolder,
                  );
                },
              ),

              const SizedBox(height: 8),

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
    if (controller.isNotesLoading.value &&
        controller.notes.isEmpty) {
      return const _NoteLoadingState();
    }

    if (controller.hasNoteError) {
      return _NoteErrorState(
        message: _cleanServerMessage(
          controller.noteErrorMessage.value,
        ),
        onRetry: controller.loadNotes,
      );
    }

    /*
     * visibleNotes already creates a new list, but we make it
     * unmodifiable so ListView itemCount and indexing always use
     * the same fixed collection during this build.
     */
    final List<NoteEntity> noteSnapshot =
    List<NoteEntity>.unmodifiable(
      controller.visibleNotes,
    );

    if (noteSnapshot.isEmpty) {
      return _EmptyNoteState(
        hasFolders: controller.folders.isNotEmpty,
        onCreate: _openCreateNoteScreen,
      );
    }

    final List<FolderEntity> folderSnapshot =
    List<FolderEntity>.unmodifiable(
      controller.folders.toList(),
    );

    return RefreshIndicator.adaptive(
      onRefresh: controller.loadAll,
      child: ListView.separated(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          120,
        ),
        itemCount: noteSnapshot.length,
        separatorBuilder: (
            BuildContext context,
            int index,
            ) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          /*
           * Extra defensive check. It should never be reached
           * because noteSnapshot is immutable.
           */
          if (index < 0 ||
              index >= noteSnapshot.length) {
            return const SizedBox.shrink();
          }

          final NoteEntity note =
          noteSnapshot[index];

          return _NoteCard(
            note: note,
            folderName: _folderNameFor(
              folderId: note.folderId,
              folders: folderSnapshot,
            ),
            onTap: () {
              controller.openNote(note.id);
            },
            onMore: () {
              _showNoteActions(
                context,
                note,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openCreateNoteScreen() async {
    if (controller.folders.isEmpty) {
      Get.snackbar(
        'Folder required',
        'Create a folder before creating a note.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    await Get.toNamed(
      AppRoutes.createNote,
    );

    await controller.loadAll();
  }

  String _folderNameFor({
    required int folderId,
    required List<FolderEntity> folders,
  }) {
    for (final FolderEntity folder in folders) {
      if (folder.id == folderId) {
        final String folderName =
        folder.name.trim();

        return folderName.isEmpty
            ? 'Unnamed Folder'
            : folderName;
      }
    }

    return 'Notes';
  }

  Future<void> _showNoteActions(
      BuildContext context,
      NoteEntity note,
      ) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (
          BuildContext sheetContext,
          ) {
        return CupertinoActionSheet(
          title: Text(
            note.title.trim().isEmpty
                ? 'Untitled Note'
                : note.title,
          ),
          message: const Text(
            'Choose an action for this note.',
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                controller.togglePin(note);
              },
              child: Text(
                note.isPinned
                    ? 'Unpin Note'
                    : 'Pin Note',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                controller.lockNote(note);
              },
              child: Text(
                note.isLocked
                    ? 'Unlock Note'
                    : 'Lock Note',
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _confirmArchiveNote(
                  context,
                  note,
                );
              },
              child: const Text(
                'Move to Recycle Bin',
              ),
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

  Future<void> _confirmArchiveNote(
      BuildContext context,
      NoteEntity note,
      ) async {
    final bool? confirmed =
    await showCupertinoDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return CupertinoAlertDialog(
          title: const Text(
            'Move note to recycle bin?',
          ),
          content: Text(
            '"${note.title.trim().isEmpty ? 'Untitled Note' : note.title}" '
                'will be removed from your active notes. '
                'You can restore it later.',
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
              child: const Text('Move'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.archiveNote(note);
  }

  String _cleanServerMessage(
      String message,
      ) {
    if (message.contains('PlainText') ||
        message.contains('PreviewText')) {
      return 'The backend note database is missing '
          'the PlainText and PreviewText columns. '
          'The database migration or note query must '
          'be corrected before notes can load.';
    }

    return message;
  }
}

class _FolderFilterStrip extends StatelessWidget {
  final List<FolderEntity> folders;
  final int? selectedFolderId;
  final VoidCallback onSelectAll;
  final ValueChanged<int> onSelectFolder;

  const _FolderFilterStrip({
    required this.folders,
    required this.selectedFolderId,
    required this.onSelectAll,
    required this.onSelectFolder,
  });

  @override
  Widget build(BuildContext context) {
    /*
     * Use one immutable collection for both itemCount and
     * folder indexing. This fixes:
     *
     * RangeError: Invalid value: Not in inclusive range
     */
    final List<FolderEntity> folderSnapshot =
    List<FolderEntity>.unmodifiable(
      folders,
    );

    return SizedBox(
      height: 44,
      child: ListView.separated(
        key: ValueKey<String>(
          'folder-filter-${folderSnapshot.length}',
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: folderSnapshot.length + 1,
        separatorBuilder: (
            BuildContext context,
            int index,
            ) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          if (index == 0) {
            return _FolderFilterChip(
              label: 'All',
              selected: selectedFolderId == null,
              onTap: onSelectAll,
            );
          }

          final int folderIndex = index - 1;

          if (folderIndex < 0 ||
              folderIndex >=
                  folderSnapshot.length) {
            return const SizedBox.shrink();
          }

          final FolderEntity folder =
          folderSnapshot[folderIndex];

          final String folderName =
          folder.name.trim();

          return _FolderFilterChip(
            key: ValueKey<int>(
              folder.id,
            ),
            label: folderName.isEmpty
                ? 'Unnamed'
                : folderName,
            selected:
            selectedFolderId == folder.id,
            onTap: () {
              onSelectFolder(folder.id);
            },
          );
        },
      ),
    );
  }
}

class _FolderFilterChip
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FolderFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(22),
        child: AnimatedContainer(
          duration:
          const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(
            maxWidth: 170,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : isDark
                ? const Color(0xFF1B1D22)
                : Colors.white,
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant
                  .withValues(
                alpha:
                isDark ? 0.22 : 0.38,
              ),
            ),
            boxShadow: <BoxShadow>[
              if (!selected)
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha:
                    isDark ? 0.08 : 0.025,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
            theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteEntity note;
  final String folderName;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _NoteCard({
    required this.note,
    required this.folderName,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color cardColor = isDark
        ? const Color(0xFF1B1D22)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius:
            BorderRadius.circular(24),
            border: Border.all(
              color: note.isPinned
                  ? colorScheme.primary
                  .withValues(alpha: 0.48)
                  : colorScheme.outlineVariant
                  .withValues(
                alpha:
                isDark ? 0.20 : 0.38,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(
                  alpha:
                  isDark ? 0.15 : 0.045,
                ),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme
                          .primaryContainer
                          .withValues(
                        alpha: 0.75,
                      ),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Icon(
                      note.isLocked
                          ? Icons
                          .lock_outline_rounded
                          : Icons
                          .description_outlined,
                      size: 21,
                      color: colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          note.title.trim().isEmpty
                              ? 'Untitled Note'
                              : note.title,
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
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.folder_outlined,
                              size: 14,
                              color: colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                folderName,
                                maxLines: 1,
                                overflow: TextOverflow
                                    .ellipsis,
                                style: theme
                                    .textTheme.bodySmall
                                    ?.copyWith(
                                  color: colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onMore,
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _notePreview(note),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(
                  color:
                  colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (note.isPinned ||
                  note.isLocked) ...<Widget>[
                const SizedBox(height: 13),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    if (note.isPinned)
                      _NoteBadge(
                        icon:
                        Icons.push_pin_outlined,
                        label: 'Pinned',
                        color:
                        colorScheme.primary,
                      ),
                    if (note.isLocked)
                      _NoteBadge(
                        icon:
                        Icons.lock_outline_rounded,
                        label: 'Locked',
                        color:
                        colorScheme.tertiary,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _notePreview(
      NoteEntity note,
      ) {
    if (note.isLocked) {
      return 'This note is locked.';
    }

    for (final Map<String, dynamic> block
    in note.content) {
      final String blockType =
          block['type']?.toString() ?? '';

      if (blockType == 'text') {
        final String text =
            block['text']?.toString().trim() ??
                '';

        if (text.isNotEmpty) {
          return text;
        }
      }

      if (blockType == 'checklist') {
        return 'Checklist content';
      }

      if (blockType == 'attachment') {
        return 'Attachment';
      }
    }

    return 'Tap to start writing.';
  }
}

class _NoteBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _NoteBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style:
            theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNoteState extends StatelessWidget {
  final bool hasFolders;
  final VoidCallback onCreate;

  const _EmptyNoteState({
    required this.hasFolders,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        final HomeController controller =
        Get.find<HomeController>();

        await controller.loadAll();
      },
      child: CustomScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
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
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary
                            .withValues(
                          alpha: 0.10,
                        ),
                        border: Border.all(
                          color: colorScheme.primary
                              .withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Icon(
                        hasFolders
                            ? Icons
                            .note_add_outlined
                            : Icons
                            .create_new_folder_outlined,
                        size: 41,
                        color:
                        colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      hasFolders
                          ? 'No notes yet'
                          : 'Create a folder first',
                      textAlign: TextAlign.center,
                      style: theme
                          .textTheme.titleLarge
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasFolders
                          ? 'Create your first note in this folder.'
                          : 'A folder is required before creating a note.',
                      textAlign: TextAlign.center,
                      style: theme
                          .textTheme.bodyMedium
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    if (hasFolders) ...<Widget>[
                      const SizedBox(height: 21),
                      FilledButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(
                          Icons.add_rounded,
                        ),
                        label: const Text(
                          'Create Note',
                        ),
                      ),
                    ],
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

class _NoteLoadingState extends StatelessWidget {
  const _NoteLoadingState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator.adaptive(
            valueColor:
            AlwaysStoppedAnimation<Color>(
              colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notes...',
            style: TextStyle(
              color:
              colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _NoteErrorState({
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
                padding: const EdgeInsets.fromLTRB(
                  30,
                  20,
                  30,
                  100,
                ),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.error
                            .withValues(
                          alpha: 0.11,
                        ),
                      ),
                      child: Icon(
                        Icons.cloud_off_outlined,
                        size: 39,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Notes are unavailable',
                      textAlign: TextAlign.center,
                      style: theme
                          .textTheme.titleLarge
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme
                          .textTheme.bodyMedium
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                        height: 1.45,
                      ),
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
            ),
          ),
        ],
      ),
    );
  }
}