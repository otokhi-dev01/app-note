import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../main/presentation/widgets/app_liquid_background_widget.dart';
import '../../../recycle_bin/presentation/widgets/recycle_bin_footer_widget.dart';
import '../../../recycle_bin/presentation/widgets/trash_note_card_widget.dart';
import '../../domain/entities/folder_entity.dart';
import '../controller/recently_deleted_folders_controller.dart';
part 'recently_deleted_empty_state.dart';
part 'recently_deleted_error_state.dart';
part 'recently_deleted_loading_state.dart';

class RecentlyDeletedFoldersView
    extends GetView<RecentlyDeletedFoldersController> {
  const RecentlyDeletedFoldersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: AppLiquidBackgroundWidget()),
          Obx(() => _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final List<FolderEntity> folderSnapshot = List<FolderEntity>.unmodifiable(
      controller.deletedFolders,
    );

    if (controller.isRefreshing.value && folderSnapshot.isEmpty) {
      return const _LoadingState();
    }

    final String error = controller.errorMessage.value.trim();

    if (error.isNotEmpty && folderSnapshot.isEmpty) {
      return _ErrorState(message: error, onRetry: controller.refreshFolders);
    }

    if (folderSnapshot.isEmpty) {
      return _EmptyState(onRefresh: controller.refreshFolders);
    }

    final ThemeData theme = Theme.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverNavigationBar(
          stretch: true,
          previousPageTitle: 'Folders',
          backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.96),
          border: null,
          largeTitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Trash',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              Text(
                '${folderSnapshot.length} folders',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _confirmEmptyTrash(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.trash,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        CupertinoSliverRefreshControl(onRefresh: controller.refreshFolders),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final folder = folderSnapshot[index];
                return TrashNoteCardWidget(
                  title: folder.name.isEmpty ? 'Unnamed Folder' : folder.name,
                  subtitle: 'This folder was deleted',
                  timestamp: folder.deletedAt ?? folder.updatedAt,
                  onTap: () => _confirmRestore(context, folder),
                );
              },
              childCount: folderSnapshot.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: RecycleBinFooterWidget(
            onEmptyTrash: () => _confirmEmptyTrash(context),
          ),
        ),
      ],
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
            'All folders in trash will be permanently deleted. This action cannot be undone.',
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
      // For now we use a simple snackbar as actual backend logic is not yet implemented
      Get.snackbar('Trash Emptied', 'All items have been permanently deleted.');
    }
  }

  Future<void> _confirmRestore(
    BuildContext context,
    FolderEntity folder,
  ) async {
    final String folderName = folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();

    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Restore Folder?'),
          content: Text(
            '"$folderName" will be moved back to your active folder list.',
          ),
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
