import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../main/presentation/widgets/app_liquid_background_widget.dart';
import '../../domain/entities/folder_entity.dart';
import '../controller/recently_deleted_folders_controller.dart';

part 'deleted_folder_card.dart';
part 'recently_deleted_empty_state.dart';
part 'recently_deleted_error_state.dart';
part 'recently_deleted_folders_header.dart';
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
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                const _RecentlyDeletedHeader(),
                Expanded(child: Obx(() => _buildContent(context))),
              ],
            ),
          ),
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

    return RefreshIndicator.adaptive(
      onRefresh: controller.refreshFolders,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: folderSnapshot.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (BuildContext context, int index) {
          if (index < 0 || index >= folderSnapshot.length) {
            return const SizedBox.shrink();
          }

          final FolderEntity folder = folderSnapshot[index];

          return _DeletedFolderCard(
            key: ValueKey<int>(folder.id),
            folder: folder,
            deletedDateText: controller.deletedDateText(folder),
            isRestoring: controller.isRestoring(folder.id),
            onRestore: () {
              _confirmRestore(context, folder);
            },
          );
        },
      ),
    );
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
