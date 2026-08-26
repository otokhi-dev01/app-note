import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_detail_more_popup.dart';

class NoteEditorTopBar extends StatelessWidget {
  final NoteDetailController controller;
  final String? title;
  final bool showShare;
  final bool showMore;
  final bool alwaysShowSave;

  final VoidCallback? onBack;

  const NoteEditorTopBar({
    super.key,
    required this.controller,
    this.onBack,
    this.title,
    this.showShare = true,
    this.showMore = true,
    this.alwaysShowSave = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return CustomGlassSliverAppBar(
      toolbarHeight: 52,
      expandedHeight: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      title: title == null
          ? null
          : Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
      leading: _GlassIconButton(
        icon: CupertinoIcons.chevron_left,

        onTap: onBack ?? () => _saveAndClose(controller),
        size: 44,
        iconSize: 28,
        color: color,
      ),
      actions: [
        _GlassIconButton(
          icon: CupertinoIcons.arrow_uturn_left,
          onTap: controller.undo,
          color: color,
        ),
        if (showShare)
          _GlassIconButton(
            icon: CupertinoIcons.share,
            onTap: controller.shareNote,
            color: color,
          ),

        if (showMore)
          NoteDetailMorePopup(
            controller: controller,
            triggerBuilder: (context, toggleMenu) =>
                MoreButton(onPressed: toggleMenu, iconColor: color),
          ),
        if (isKeyboardVisible || alwaysShowSave)
          Obx(
            () => controller.isReadOnly.value
                ? const SizedBox.shrink()
                : Row(children: [_SaveButton(controller: controller)]),
          ),
      ],
    );
  }
}

Future<void> _saveAndClose(NoteDetailController controller) async {
  if (!controller.isReadOnly.value) {
    await controller.saveNote(silent: true);
  }
  Get.back(result: true);
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
