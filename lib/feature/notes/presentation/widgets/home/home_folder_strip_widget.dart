import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../folders/domain/entities/folder_entity.dart';
import '../../controllers/home_controller.dart';
import 'home_color_utils.dart';

part 'folder_pill_widget.dart';
part 'add_folder_pill_widget.dart';

class HomeFolderStrip extends GetView<HomeController> {
  final VoidCallback onCreateFolder;

  const HomeFolderStrip({super.key, required this.onCreateFolder});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<FolderEntity> folders = controller.folders;

      final int? selectedFolderId = controller.selectedFolderId.value;

      return SizedBox(
        height: 48,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: folders.length + 2,
          separatorBuilder: (_, _) {
            return const SizedBox(width: 8);
          },
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return _FolderPill(
                label: 'All',
                count: null,
                selected: selectedFolderId == null,
                color: Theme.of(context).colorScheme.primary,
                onTap: controller.selectAllNotes,
              );
            }

            if (index == folders.length + 1) {
              return _AddFolderPill(
                isLoading: controller.isFoldersLoading.value,
                onTap: onCreateFolder,
              );
            }

            final FolderEntity folder = folders[index - 1];

            return _FolderPill(
              label: folder.name.trim().isEmpty ? 'Unnamed' : folder.name,
              count: folder.noteCount,
              selected: selectedFolderId == folder.id,
              color: parseFolderColor(
                folder.colorValue,
                Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                controller.selectFolder(folder.id);
              },
            );
          },
        ),
      );
    });
  }
}
