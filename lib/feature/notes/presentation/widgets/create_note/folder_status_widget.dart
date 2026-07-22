part of '../../view/create_note_view.dart';

class _FolderStatus extends GetView<CreateNoteController> {
  const _FolderStatus();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<FolderEntity> folders = controller.folders;
      final int? selectedId = controller.selectedFolderId.value;

      return SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: folders.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == folders.length) {
              return _AddFolderChip(onTap: () => _openCreateFolder(context));
            }

            final FolderEntity folder = folders[index];
            return _FolderChip(
              folder: folder,
              isSelected: selectedId == folder.id,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.selectFolder(folder.id);
              },
            );
          },
        ),
      );
    });
  }

  Future<void> _openCreateFolder(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final dynamic result = await Get.toNamed(AppRoutes.createFolder);
    if (result == true) {
      await controller.loadFolders();
    }
  }
}

class _FolderChip extends StatelessWidget {
  final FolderEntity folder;
  final bool isSelected;
  final VoidCallback onTap;

  const _FolderChip({
    required this.folder,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    final String name = folder.name.trim().isEmpty ? 'Unnamed' : folder.name.trim();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AppGlassSurface(
        borderRadius: 19,
        padding: EdgeInsets.zero,
        blur: 16,
        tintColor: isSelected
            ? colors.primary.withValues(alpha: 0.85)
            : colors.surface.withValues(alpha: isDark ? 0.35 : 0.65),
        borderColor: isSelected
            ? colors.primary
            : colors.outlineVariant.withValues(alpha: 0.2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddFolderChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddFolderChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AppGlassSurface(
      borderRadius: 19,
      padding: EdgeInsets.zero,
      blur: 16,
      tintColor: colors.surface.withValues(alpha: isDark ? 0.25 : 0.45),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(
            CupertinoIcons.add,
            size: 18,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
