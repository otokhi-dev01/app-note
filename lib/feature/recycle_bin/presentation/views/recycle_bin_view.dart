import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/main/presentation/widgets/app_liquid_background_widget.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../controllers/recycle_bin_controller.dart';

class RecycleBinView
    extends GetView<RecycleBinController> {
  const RecycleBinView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: AppLiquidBackgroundWidget(),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                _RecycleBinHeader(
                  onBack: Get.back,
                  onRefresh:
                  controller.refreshData,
                ),
                Expanded(
                  child: Obx(
                        () => _buildContent(context),
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
    if (controller.isRefreshing.value &&
        controller.isEmpty) {
      return const Center(
        child:
        CircularProgressIndicator.adaptive(),
      );
    }

    if (controller.errorMessage.value.isNotEmpty &&
        controller.isEmpty) {
      return _RecycleBinError(
        message:
        controller.errorMessage.value,
        onRetry: controller.refreshData,
      );
    }

    if (controller.isEmpty) {
      return _EmptyRecycleBin(
        onRefresh: controller.refreshData,
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: controller.refreshData,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding:
        const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          32,
        ),
        children: <Widget>[
          if (controller
              .deletedFolders.isNotEmpty) ...<
              Widget>[
            _SectionTitle(
              title: 'Deleted folders',
              count: controller
                  .deletedFolders.length,
            ),
            const SizedBox(height: 10),
            ...controller.deletedFolders.map(
                  (FolderEntity folder) {
                return Padding(
                  key: ValueKey<int>(folder.id),
                  padding:
                  const EdgeInsets.only(
                    bottom: 11,
                  ),
                  child: _DeletedFolderCard(
                    folder: folder,
                    onRestore: () {
                      _confirmRestoreFolder(
                        context,
                        folder,
                      );
                    },
                  ),
                );
              },
            ),
          ],
          if (controller
              .archivedNotes.isNotEmpty) ...<
              Widget>[
            if (controller
                .deletedFolders.isNotEmpty)
              const SizedBox(height: 18),
            _SectionTitle(
              title: 'Archived notes',
              count:
              controller.archivedNotes.length,
            ),
            const SizedBox(height: 10),
            ...controller.archivedNotes.map(
                  (NoteEntity note) {
                return Padding(
                  key: ValueKey<int>(note.id),
                  padding:
                  const EdgeInsets.only(
                    bottom: 11,
                  ),
                  child: _ArchivedNoteCard(
                    note: note,
                    onRestore: () {
                      controller.restoreNote(note);
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRestoreFolder(
      BuildContext context,
      FolderEntity folder,
      ) async {
    final String name =
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
          title:
          const Text('Restore folder?'),
          content: Text(
            'Restore "$name" and make it '
                'available again?',
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
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.restoreFolder(folder);
    }
  }
}

class _RecycleBinHeader
    extends StatelessWidget {
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;

  const _RecycleBinHeader({
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8,
      ),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onBack,
            child:
            const Icon(CupertinoIcons.back),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Recycle Bin',
                  style: theme
                      .textTheme.headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Restore deleted folders and '
                      'archived notes',
                  style: theme
                      .textTheme.bodySmall
                      ?.copyWith(
                    color: theme.colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onRefresh,
            child:
            const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle
    extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge
                ?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary
                .withValues(alpha: 0.11),
            borderRadius:
            BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeletedFolderCard
    extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback onRestore;

  const _DeletedFolderCard({
    required this.folder,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;
    final bool isDark =
        theme.brightness == Brightness.dark;

    final String name =
    folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(
            alpha: isDark ? 0.18 : 0.35,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.error
                  .withValues(alpha: 0.11),
              borderRadius:
              BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.folder_delete_outlined,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: theme
                      .textTheme.titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
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
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRestore,
            icon: const Icon(
              Icons.restore_rounded,
            ),
            label: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}

class _ArchivedNoteCard
    extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback onRestore;

  const _ArchivedNoteCard({
    required this.note,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;
    final bool isDark =
        theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(
            alpha: isDark ? 0.18 : 0.35,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.secondary
                  .withValues(alpha: 0.12),
              borderRadius:
              BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.archive_outlined,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              note.title.trim().isEmpty
                  ? 'Untitled Note'
                  : note.title,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style: theme
                  .textTheme.titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onRestore,
            icon: const Icon(
              Icons.restore_rounded,
            ),
            label: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecycleBin
    extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyRecycleBin({
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
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(
            height:
            MediaQuery.sizeOf(context).height *
                0.62,
            child: Center(
              child: Padding(
                padding:
                const EdgeInsets.all(32),
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
                      ),
                      child: Icon(
                        Icons
                            .delete_outline_rounded,
                        size: 42,
                        color:
                        colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Recycle bin is empty',
                      style: theme
                          .textTheme.titleLarge
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deleted folders and '
                          'archived notes will '
                          'appear here.',
                      textAlign:
                      TextAlign.center,
                      style: theme
                          .textTheme.bodyMedium
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
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

class _RecycleBinError
    extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _RecycleBinError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    return RefreshIndicator.adaptive(
      onRefresh: onRetry,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: <Widget>[
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load recycle bin',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(
              color: theme.colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
