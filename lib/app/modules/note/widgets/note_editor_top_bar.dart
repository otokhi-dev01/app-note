import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/note_detail_controller.dart';

class NoteEditorTopBar extends StatelessWidget {
  final NoteDetailController controller;
  final VoidCallback onShowMoreMenu;

  const NoteEditorTopBar({
    super.key,
    required this.controller,
    required this.onShowMoreMenu,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(top: topPadding),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SizedBox(
          height: 45,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GlassIconButton(
                icon: CupertinoIcons.chevron_left,
                onTap: Get.back,
                size: 44,
                iconSize: 28,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              Row(
                children: [
                  _GlassIconButton(
                    icon: CupertinoIcons.arrow_uturn_left,
                    onTap: controller.undo,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 15),
                  _GlassIconButton(
                    icon: CupertinoIcons.share,
                    onTap: controller.shareNote,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 15),
                  MoreButton(
                    onPressed: onShowMoreMenu,
                    iconColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 15),
                  Obx(
                    () => controller.isReadOnly.value
                        ? const SizedBox.shrink()
                        : _SaveButton(controller: controller),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color color;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 24,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return CustomGlassButton(
      onPressed: onTap,
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      shape: GlassShape.circle,
      foregroundColor: color,
      blur: 10,
      opacity: 0.15,
      thickness: 8,
      child: Icon(icon, size: iconSize),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final NoteDetailController controller;

  const _SaveButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomGlassButton(
        onPressed: controller.isSaving.value ? null : controller.saveNote,
        width: 44,
        height: 44,
        padding: EdgeInsets.zero,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        child: controller.isSaving.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.folderPink,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                CupertinoIcons.checkmark,
                color: AppTheme.folderPink,
                size: 22,
                fontWeight: FontWeight.bold,
              ),
      ),
    );
  }
}
