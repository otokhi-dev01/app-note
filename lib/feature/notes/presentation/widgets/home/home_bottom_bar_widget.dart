import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import 'glass_surface_widget.dart';

class HomeBottomBar
    extends GetView<HomeController> {
  final VoidCallback onCreateNote;

  const HomeBottomBar({
    super.key,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool canCreateNote =
          controller.folders.isNotEmpty;

      final String folderName =
          controller.selectedFolderName;

      return _BottomBarContent(
        folderName: folderName,
        canCreateNote: canCreateNote,
        onCreateNote: onCreateNote,
      );
    });
  }
}

class _BottomBarContent extends StatelessWidget {
  final String folderName;
  final bool canCreateNote;
  final VoidCallback onCreateNote;

  const _BottomBarContent({
    required this.folderName,
    required this.canCreateNote,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return GlassSurface(
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.fromLTRB(
        17,
        10,
        10,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  canCreateNote
                      ? 'Create in'
                      : 'Get started',
                  style:
                  theme.textTheme.labelSmall?.copyWith(
                    color:
                    colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  canCreateNote
                      ? folderName
                      : 'Create a folder first',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                  theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onCreateNote,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color:
                    colorScheme.primary.withValues(
                      alpha: 0.28,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    canCreateNote
                        ? Icons.add_rounded
                        : Icons
                        .create_new_folder_outlined,
                    color: colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    canCreateNote
                        ? 'New Note'
                        : 'New Folder',
                    style:
                    theme.textTheme.labelLarge
                        ?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}