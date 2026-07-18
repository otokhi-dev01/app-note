part of '../home_controller.dart';

extension _HomeFolderActions on HomeController {
  Future<void> _syncFoldersAction() async {
    if (isFolderSyncing.value) return;
    try {
      isFolderSyncing.value = true;
      final remoteAndCachedFolders = await _getFolders();
      folders.assignAll(remoteAndCachedFolders);
    } catch (error) {
      _showStatusSnackbar('Folder Sync', error.toString(), isDestructive: true);
    } finally {
      isFolderSyncing.value = false;
    }
  }

  Future<void> _openCreateFolder() async {
    HapticFeedback.lightImpact();
    final result = await Get.to<String>(
      () => const CreateFolderView(),
      fullscreenDialog: true,
    );
    if (result == null) return;

    try {
      isFolderSyncing.value = true;
      await _createFolder(result);
      await loadNotes();
      _showStatusSnackbar('Folder Saved', '“$result” is ready.');
    } catch (error) {
      _showStatusSnackbar(
        'Folder Save Failed',
        error.toString(),
        isDestructive: true,
      );
    } finally {
      isFolderSyncing.value = false;
    }
  }

  Future<void> _deleteFolderAction(Folder folder) async {
    if (folder.id == null) return;
    Get.dialog(
      CupertinoAlertDialog(
        title: Text('Delete "${folder.name}"?'),
        content: const Text(
          'This folder will be deleted. Any notes inside will be kept but unorganized.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Get.back();
              try {
                isFolderSyncing.value = true;
                await _deleteFolder(folder.id!);
                await loadNotes();
                _showFolderDeletedSnackbar(folder);
              } catch (error) {
                _showStatusSnackbar(
                  'Delete Failed',
                  error.toString(),
                  isDestructive: true,
                );
              } finally {
                isFolderSyncing.value = false;
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameFolderAction(Folder folder) async {
    if (folder.id == null) return;
    final textController = TextEditingController(text: folder.name);
    Get.dialog(
      CupertinoAlertDialog(
        title: const Text('Rename Folder'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Folder Name',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty && newName != folder.name) {
                try {
                  isFolderSyncing.value = true;
                  await _renameFolder(folder.id!, newName);
                  await loadNotes();
                  _showStatusSnackbar(
                    'Folder Updated',
                    'Folder renamed to “$newName”.',
                  );
                } catch (error) {
                  _showStatusSnackbar(
                    'Rename Failed',
                    error.toString(),
                    isDestructive: true,
                  );
                } finally {
                  isFolderSyncing.value = false;
                }
              }
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreFolderAction(Folder folder) async {
    if (folder.id == null || isFolderSyncing.value) return;
    try {
      isFolderSyncing.value = true;
      await _restoreFolder(folder.id!);
      await loadNotes();
      _showStatusSnackbar('Folder Restored', '“${folder.name}” was restored.');
    } catch (error) {
      _showStatusSnackbar(
        'Restore Failed',
        error.toString(),
        isDestructive: true,
      );
    } finally {
      isFolderSyncing.value = false;
    }
  }

  void _showFolderDeletedSnackbar(Folder folder) {
    Get.snackbar(
      'Folder Deleted',
      '“${folder.name}” can be restored.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.surface,
      colorText: Get.theme.colorScheme.onSurface,
      margin: const EdgeInsets.all(15),
      borderRadius: 15,
      mainButton: TextButton(
        onPressed: () async {
          Get.closeCurrentSnackbar();
          await restoreFolder(folder);
        },
        child: const Text('Restore'),
      ),
    );
  }
}
