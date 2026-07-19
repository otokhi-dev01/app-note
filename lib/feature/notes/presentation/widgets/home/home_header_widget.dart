import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import 'glass_surface_widget.dart';

class HomeHeader extends GetView<HomeController> {
  final VoidCallback onOpenFolders;
  final VoidCallback onOpenMenu;

  const HomeHeader({
    super.key,
    required this.onOpenFolders,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isLoading =
          controller.isNotesLoading.value ||
              controller.isFoldersLoading.value;

      return GlassSurface(
        padding: const EdgeInsets.fromLTRB(
          18,
          15,
          10,
          15,
        ),
        child: _HeaderContent(
          title: controller.selectedFolderName,
          noteCount:
          controller.selectedFolderNoteCount,
          isLoading: isLoading,
          onOpenFolders: onOpenFolders,
          onRefresh: controller.loadAll,
          onOpenMenu: onOpenMenu,
        ),
      );
    });
  }
}

class _HeaderContent extends StatelessWidget {
  final String title;
  final int noteCount;
  final bool isLoading;
  final VoidCallback onOpenFolders;
  final VoidCallback onRefresh;
  final VoidCallback onOpenMenu;

  const _HeaderContent({
    required this.title,
    required this.noteCount,
    required this.isLoading,
    required this.onOpenFolders,
    required this.onRefresh,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenFolders,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: theme
                            .textTheme.headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color:
                      colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$noteCount '
                      '${noteCount == 1 ? 'note' : 'notes'}',
                  style:
                  theme.textTheme.bodyMedium?.copyWith(
                    color:
                    colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator.adaptive(
                strokeWidth: 2,
              ),
            ),
          )
        else
          _GlassIconButton(
            icon: Icons.refresh_rounded,
            onPressed: onRefresh,
          ),

        const SizedBox(width: 4),

        _GlassIconButton(
          icon: Icons.more_horiz_rounded,
          onPressed: onOpenMenu,
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.onSurface.withValues(
            alpha: 0.06,
          ),
          border: Border.all(
            color:
            colorScheme.outlineVariant.withValues(
              alpha: 0.28,
            ),
          ),
        ),
        child: Icon(
          icon,
          size: 21,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}