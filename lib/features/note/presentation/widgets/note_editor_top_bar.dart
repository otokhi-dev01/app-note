import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_detail_more_popup.dart';

class NoteEditorTopBar extends StatelessWidget {
  final NoteDetailController controller;

  /// What Back does. Defaults to save-then-close, which is right for a note
  /// that already exists. [CreateNoteView] overrides it: a blank new note must
  /// never be written just because the user backed out of it, so it goes
  /// through `saveAndExitIfNeeded` instead.
  final VoidCallback? onBack;

  const NoteEditorTopBar({
    super.key,
    required this.controller,
    this.onBack,
  });

  // A sliver (not a fixed-position overlay) so it scrolls with the note
  // body the same way every other screen's CustomGlassSliverAppBar does
  // (Folder, Recently Deleted, Note List) — pinned at a fixed compact
  // height rather than expanding into a large title, since the note's own
  // title is edited inline in the content below.
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    // Only while actively editing (keyboard up) — once it's dismissed
    // (tapping away, or after Save itself unfocuses), the bar goes back to
    // the plain back/undo/share/more row instead of keeping a checkmark
    // around with nothing left to confirm.
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return CustomGlassSliverAppBar(
      toolbarHeight: 52,
      expandedHeight: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      leading: _GlassIconButton(
        icon: CupertinoIcons.chevron_left,
        // The note list only re-fetches after returning here when the popped
        // result is `true` (see NoteListTile/NoteGridTile) — without this,
        // edits made in this screen (deleting an attachment, retitling, …)
        // never show up until the list is refreshed some other way.
        //
        // The Save button only renders while the keyboard is up, so an edit
        // made without ever bringing up the keyboard (toggling a checklist
        // item, deleting an attachment via its own button, …) would
        // otherwise have no save path at all — there's no autosave anywhere
        // else in this controller. Save silently here as a safety net
        // before leaving, regardless of how the note was edited.
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
        _GlassIconButton(
          icon: CupertinoIcons.share,
          onTap: controller.shareNote,
          color: color,
        ),
        // The button is the menu's trigger now — it morphs into the pull-down
        // rather than calling out to a screen-level popup, so the screens no
        // longer route a callback down here just to open it.
        NoteDetailMorePopup(
          controller: controller,
          triggerBuilder: (context, toggleMenu) =>
              MoreButton(onPressed: toggleMenu, iconColor: color),
        ),
        if (isKeyboardVisible)
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
