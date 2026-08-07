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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GlassIconButton(
                icon: CupertinoIcons.chevron_left,
                onTap: Get.back,
                size: 44,
                iconSize: 28,
              ),
              Row(
                children: [
                  _GlassIconButton(
                    icon: CupertinoIcons.arrow_uturn_left,
                    onTap: controller.undo,
                  ),
                  const SizedBox(width: 15),
                  _GlassIconButton(
                    icon: CupertinoIcons.share,
                    onTap: controller.shareNote,
                  ),
                  const SizedBox(width: 15),
                  _GlassIconButton(
                    icon: Icons.more_horiz,
                    onTap: onShowMoreMenu,
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
  final double opacity;
  final Color color;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 22,
    this.opacity = 0.15,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      width: size,
      height: size,
      borderRadius: size / 2,
      opacity: opacity,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onTap,
        icon: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final NoteDetailController controller;

  const _SaveButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      width: 40,
      height: 40,
      borderRadius: 20,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.saveNote,
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.folderYellow,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Obx(
            () => controller.isSaving.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    CupertinoIcons.checkmark,
                    color: AppTheme.bodyColor,
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }
}
