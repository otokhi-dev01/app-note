import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../controllers/recycle_bin_controller.dart';
import '../widgets/empty_recycle_bin_state_widget.dart';
import '../widgets/recycle_bin_error_state_widget.dart';
import '../widgets/recycle_bin_footer_widget.dart';
import '../widgets/recycle_bin_loading_state_widget.dart';
import '../widgets/trash_note_card_widget.dart';

class RecycleBinView extends GetView<RecycleBinController> {
  final bool isArchiveMode;
  const RecycleBinView({super.key, this.isArchiveMode = false});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color pageColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: pageColor,
      body: Obx(() {
        final List<FolderEntity> deletedFolders =
            List<FolderEntity>.unmodifiable(controller.deletedFolders);
        final List<NoteEntity> archivedNotes = List<NoteEntity>.unmodifiable(
          controller.archivedNotes,
        );
        final bool isEmpty = deletedFolders.isEmpty && archivedNotes.isEmpty;
        final bool isInitialLoading = controller.isRefreshing.value && isEmpty;
        final String errorMessage = controller.errorMessage.value.trim();
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),

          slivers: <Widget>[
            CupertinoSliverNavigationBar(
              stretch: true,
              previousPageTitle: 'Back',
              backgroundColor: pageColor.withValues(alpha: 0.96),
              border: null,
              largeTitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArchiveMode ? 'Archive' : 'Trash',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  Text(
                    '${isArchiveMode ? archivedNotes.length : archivedNotes.length + deletedFolders.length} ${isArchiveMode ? 'notes' : 'items'}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (isArchiveMode) {
                    // Show filter options for archive
                  } else {
                    _confirmEmptyTrash(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isArchiveMode ? CupertinoIcons.slider_horizontal_3 : CupertinoIcons.trash,
                    size: 20,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
            CupertinoSliverRefreshControl(onRefresh: controller.refreshData),
            if (isInitialLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: RecycleBinLoadingStateWidget(),
              )
            else if (errorMessage.isNotEmpty && isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: RecycleBinErrorStateWidget(
                  message: errorMessage,
                  onRetry: controller.refreshData,
                ),
              )
            else if (isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyRecycleBinStateWidget(
                  onRefresh: controller.refreshData,
                ),
              )
            else ...<Widget>[
              if (isArchiveMode ? archivedNotes.isNotEmpty : (deletedFolders.isNotEmpty || archivedNotes.isNotEmpty))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (isArchiveMode) {
                          final note = archivedNotes[index];
                          return TrashNoteCardWidget(
                            title: note.title.isEmpty ? 'Untitled Note' : note.title,
                            subtitle: 'This note is in archive',
                            timestamp: note.deletedAt ?? note.updatedAt,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              controller.restoreNote(note);
                            },
                            isArchive: true,
                          );
                        }

                        if (index < deletedFolders.length) {
                          final folder = deletedFolders[index];
                          return TrashNoteCardWidget(
                            title: folder.name.isEmpty ? 'Unnamed Folder' : folder.name,
                            subtitle: 'This folder was deleted',
                            timestamp: folder.deletedAt ?? folder.updatedAt,
                            onTap: () => _confirmRestoreFolder(context, folder),
                          );
                        } else {
                          final noteIndex = index - deletedFolders.length;
                          final note = archivedNotes[noteIndex];
                          return TrashNoteCardWidget(
                            title: note.title.isEmpty ? 'Untitled Note' : note.title,
                            subtitle: 'This note was deleted',
                            timestamp: note.deletedAt ?? note.updatedAt,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              controller.restoreNote(note);
                            },
                          );
                        }
                      },
                      childCount: isArchiveMode ? archivedNotes.length : (deletedFolders.length + archivedNotes.length),
                    ),
                  ),
                ),
              if (!isArchiveMode)
                SliverToBoxAdapter(
                  child: RecycleBinFooterWidget(
                    onEmptyTrash: () => _confirmEmptyTrash(context),
                  ),
                ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      }),
    );
  }

  Future<void> _confirmEmptyTrash(BuildContext context) async {
    HapticFeedback.heavyImpact();

    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Empty Trash?'),
          content: const Text(
            'All notes and folders in trash will be permanently deleted. This action cannot be undone.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Empty Trash'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.emptyTrash();
    }
  }

  Future<void> _confirmRestoreFolder(
    BuildContext context,
    FolderEntity folder,
  ) async {
    HapticFeedback.mediumImpact();

    final String folderName = folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Restore Folder?'),
          content: Text('Restore “$folderName” and make it available again?'),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.restoreFolder(folder);
  }
}
