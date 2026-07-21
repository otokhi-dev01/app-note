import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../folders/domain/entities/folder_entity.dart';
import '../../controllers/home_controller.dart';
import 'home_color_utils_widget.dart';

class HomeFolderStrip
    extends GetView<HomeController> {
  final VoidCallback onCreateFolder;

  const HomeFolderStrip({
    super.key,
    required this.onCreateFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<FolderEntity> folders =
          controller.folders;

      final int? selectedFolderId =
          controller.selectedFolderId.value;

      return SizedBox(
        height: 48,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          scrollDirection: Axis.horizontal,
          itemCount: folders.length + 2,
          separatorBuilder: (_, _) {
            return const SizedBox(width: 8);
          },
          itemBuilder: (
              BuildContext context,
              int index,
              ) {
            if (index == 0) {
              return _FolderPill(
                label: 'All',
                count: null,
                selected: selectedFolderId == null,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
                onTap: controller.selectAllNotes,
              );
            }

            if (index == folders.length + 1) {
              return _AddFolderPill(
                isLoading: controller
                    .isFoldersLoading.value,
                onTap: onCreateFolder,
              );
            }

            final FolderEntity folder =
            folders[index - 1];

            return _FolderPill(
              label: folder.name.trim().isEmpty
                  ? 'Unnamed'
                  : folder.name,
              count: folder.noteCount,
              selected:
              selectedFolderId == folder.id,
              color: parseFolderColor(
                folder.colorValue,
                Theme.of(context)
                    .colorScheme
                    .primary,
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

class _FolderPill extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FolderPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(
            alpha: isDark ? 0.28 : 0.16,
          )
              : colorScheme.surface.withValues(
            alpha: isDark ? 0.48 : 0.64,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.62)
                : colorScheme.outlineVariant
                .withValues(alpha: 0.34),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? color
                    : colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style:
              theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? color
                    : colorScheme.onSurface,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 7),
              Text(
                count.toString(),
                style:
                theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? color
                      : colorScheme
                      .onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddFolderPill extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _AddFolderPill({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isLoading ? null : onTap,
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface.withValues(
            alpha: 0.62,
          ),
          border: Border.all(
            color:
            colorScheme.outlineVariant.withValues(
              alpha: 0.34,
            ),
          ),
        ),
        child: isLoading
            ? const Padding(
          padding: EdgeInsets.all(12),
          child:
          CircularProgressIndicator.adaptive(
            strokeWidth: 2,
          ),
        )
            : Icon(
          Icons.add_rounded,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
