import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import 'home_folder_sheet.dart';

abstract final class HomeOverlays {
  static Future<void> showFolderSheet({
    required BuildContext context,
    required HomeController controller,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor:
      Colors.black.withValues(alpha: 0.24),
      builder: (BuildContext sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: Obx(() {
            final int totalNoteCount =
            controller.notes.isNotEmpty
                ? controller.notes.length
                : controller.folders.fold<int>(
              0,
                  (
                  int total,
                  folder,
                  ) {
                return total +
                    folder.noteCount;
              },
            );

            return HomeFolderSheet(
              folders: controller.folders,
              selectedFolderId:
              controller.selectedFolderId.value,
              totalNoteCount: totalNoteCount,
              onSelectAll: () {
                controller.selectAllNotes();
                Navigator.of(sheetContext).pop();
              },
              onSelectFolder: (int folderId) {
                controller.selectFolder(folderId);
                Navigator.of(sheetContext).pop();
              },
              onCreateFolder: () {
                Navigator.of(sheetContext).pop();

                Future<void>.delayed(
                  const Duration(
                    milliseconds: 180,
                  ),
                      () {
                    if (!context.mounted) {
                      return;
                    }

                    showCreateFolder(
                      context: context,
                      controller: controller,
                    );
                  },
                );
              },
            );
          }),
        );
      },
    );
  }

  static Future<void> showCreateFolder({
    required BuildContext context,
    required HomeController controller,
  }) async {
    String folderName = '';

    final String? result =
    await showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
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

                if (name.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext)
                    .pop(name);
              },
            ),
          ),
          actions: [
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

                if (name.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext)
                    .pop(name);
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

  static Future<void> showCreateNote({
    required BuildContext context,
    required HomeController controller,
  }) async {
    if (controller.folders.isEmpty) {
      await showCreateFolder(
        context: context,
        controller: controller,
      );

      return;
    }

    String noteTitle = '';

    final String? result =
    await showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('New Note'),
          content: Padding(
            padding:
            const EdgeInsets.only(top: 14),
            child: CupertinoTextField(
              autofocus: true,
              placeholder: 'Note title',
              textInputAction:
              TextInputAction.done,
              onChanged: (String value) {
                noteTitle = value;
              },
              onSubmitted: (String value) {
                final String title =
                value.trim();

                if (title.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext)
                    .pop(title);
              },
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final String title =
                noteTitle.trim();

                if (title.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext)
                    .pop(title);
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

    await controller.createNote(
      title: result,
    );
  }

  static Future<void> showAccountSheet({
    required BuildContext context,
    required HomeController controller,
  }) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Piisiit Note'),
          message: const Text(
            'Choose an account action.',
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.loadAll();
              },
              child: const Text('Refresh Data'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.logout();
              },
              child: const Text('Sign Out'),
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
}