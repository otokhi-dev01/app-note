import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_attachment_popup.dart';
import 'package:Note/features/note/presentation/widgets/note_block_list.dart';
import 'package:Note/features/note/presentation/widgets/note_detail_more_popup.dart';
import 'package:Note/features/note/presentation/widgets/note_format_panel.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// The dedicated screen for composing a brand-new note (`noteId == 0`),
/// redesigned to match the iOS 26 Apple Notes editor. Opening an *existing*
/// note still uses NoteDetailView/NoteContentEditor — see
/// NoteNavigation.toNewNote (routes here) vs .toDetail (routes there).
///
/// This screen intentionally reuses [NoteDetailController] rather than a
/// second, parallel controller: `_initNewNote` already never calls the API
/// on its own (a blank note is 100% local until something is worth saving —
/// see [NoteDetailController.saveAndExitIfNeeded] and the autosave wiring in
/// the controller for exactly when the first save happens), so the
/// create-note contract this screen needs was already there. No model
/// fields were added — `Note`/`NoteBlock` are unchanged.
class CreateNoteView extends GetView<NoteDetailController> {
  const CreateNoteView({super.key, this.tag});

  @override
  // ignore: overridden_fields
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiStyle(theme),
      child: Scaffold(
        // FIX: plain background, no card behind the editor — per spec this
        // screen is a flat full-screen writing surface.
        backgroundColor: theme.scaffoldBackgroundColor,
        // FIX: keyboard opening must not resize/reflow the whole Scaffold —
        // the bottom toolbar tracks MediaQuery.viewInsets.bottom itself
        // (see the Obx below that positions it), and letting the Scaffold
        // *also* resize on top of that would double-apply the keyboard
        // height.
        resizeToAvoidBottomInset: false,
        // FIX: no Scaffold-level SafeArea here — _TopBar and _BottomToolbar
        // each already wrap themselves in their own SafeArea (top-only /
        // bottom-only respectively), matching every other floating bar in
        // this app (NoteEditorTopBar, NoteListBottomBar, …). Adding a second
        // SafeArea around the whole Stack would apply the top/bottom safe
        // insets twice, pushing both bars further in than intended.
        body: Stack(
          children: [
            // Scrollable body: title, metadata, blocks. Padded at both
            // ends so neither the floating top bar nor the floating
            // bottom toolbar ever covers real content — see _CreateNoteBody.
            _CreateNoteBody(controller: controller),

            // FIX: floating top bar is a Stack/Positioned overlay, not a
            // sliver — it never scrolls away, matching "floating iOS-style
            // top bar" instead of the scrolling app-bar NoteDetailView uses.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(controller: controller),
            ),

            // FIX: bottom toolbar is also a plain Stack/Positioned child —
            // never inside the scroll content — and is repositioned every
            // frame against the live keyboard inset, so it always floats
            // just above the keyboard instead of being pushed off-screen
            // or hidden behind it.
            Obx(() {
              if (controller.isReadOnly.value) {
                return const SizedBox.shrink();
              }
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;
              return Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  // FIX: the format panel replaces the toolbar outright
                  // instead of stacking on top of it, so the two can never
                  // visually overlap.
                  child: controller.isFormatPanelVisible.value
                      ? NoteFormatPanel(
                          key: const ValueKey('format-panel'),
                          controller: controller,
                        )
                      : _BottomToolbar(
                          key: const ValueKey('bottom-toolbar'),
                          controller: controller,
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  SystemUiOverlayStyle _systemUiStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final style = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return style.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }
}

/// Left: back (saves-if-needed, never creates an empty note). Right: more.
class _TopBar extends StatelessWidget {
  final NoteDetailController controller;

  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: _MaxWidth(
          child: Row(
            children: [
              _GlassIcon(
                icon: CupertinoIcons.chevron_back,
                semanticLabel: 'Back',
                color: color,
                onTap: () => _handleBack(),
              ),
              const Spacer(),
              _GlassIcon(
                icon: CupertinoIcons.ellipsis,
                semanticLabel: 'More options',
                color: color,
                onTap: () =>
                    NoteDetailMorePopup.show(context: context, controller: controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIX: "If the user opens Create Note and does nothing, pressing Back
  // must not create an empty note" — saveAndExitIfNeeded only calls the API
  // if there's real content; on a genuinely empty note it's a pure no-op,
  // so Back never touches the network here.
  Future<void> _handleBack() async {
    await controller.saveAndExitIfNeeded();
    Get.back(result: true);
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  const _GlassIcon({
    required this.icon,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomGlassButton(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      width: 40,
      height: 40,
      padding: EdgeInsets.zero,
      shape: GlassShape.circle,
      foregroundColor: color,
      blur: 10,
      opacity: 0.15,
      thickness: 8,
      child: Icon(icon, size: 22),
    );
  }
}

/// Title, "Today at 3:42 PM • Folder" metadata (with a small inline
/// "Saving…" indicator), and the block body — the entire thing scrollable,
/// with enough top/bottom padding to clear the floating bars.
class _CreateNoteBody extends StatelessWidget {
  final NoteDetailController controller;

  const _CreateNoteBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // FIX: top padding clears the status bar plus the floating top bar's
    // own height (40 button + 8 top inset + 12 breathing room) — computed
    // from the real device safe-area inset rather than a flat guess, since
    // there's no Scaffold-level SafeArea reserving that space anymore (see
    // the comment on `body:` above).
    final topPadding = MediaQuery.paddingOf(context).top + 60;
    // FIX: enough bottom padding that the last line is never hidden behind
    // the floating bottom toolbar — 140 covers the toolbar's own height
    // plus its floating margin; the keyboard inset is added on top so the
    // gap grows further whenever the keyboard is up.
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 140;

    return Obx(() {
      final isReadOnly = controller.isReadOnly.value;
      final note = controller.currentNote.value;
      final noteDate = note?.updatedAt ?? DateTime.now();
      final folderName = _resolveFolderName(note?.folderId ?? 0);

      return SingleChildScrollView(
        // FIX: manual dismiss (not onDrag) so scrolling the note while
        // actively typing doesn't fight the cursor-follows-keyboard
        // behavior, matching NoteContentEditor's existing editor.
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, bottomPadding),
        child: _MaxWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('create-note-title-field'),
                controller: controller.titleController,
                enabled: !isReadOnly,
                // A brand-new note opens with the cursor already in the
                // title, keyboard up — no extra tap needed to start typing.
                autofocus: !isReadOnly,
                cursorColor: AppTheme.folderYellow,
                cursorWidth: 1.5,
                maxLines: null,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => controller.focusFirstTextBlock(),
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 32,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isCollapsed: true,
                  filled: false,
                  fillColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _metaLine(noteDate, folderName, controller.isSaving.value),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              NoteBlockList(
                controller: controller,
                textPlaceholder: 'Start writing...',
              ),
              if (!isReadOnly)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: controller.focusLastTextBlock,
                  child: const SizedBox(height: 200, width: double.infinity),
                ),
            ],
          ),
        ),
      );
    });
  }

  String _metaLine(DateTime date, String folderName, bool isSaving) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final dateLabel = isToday
        ? 'Today at ${DateFormat('h:mm a').format(date)}'
        : DateFormat("MMMM d, yyyy 'at' h:mm a").format(date);
    final withFolder = folderName.isEmpty
        ? dateLabel
        : '$dateLabel • $folderName';
    // FIX: small inline "Saving…" indicator — never a blocking spinner over
    // the whole screen, just appended to the metadata line while an
    // autosave (or the final save-on-exit) is actually in flight.
    return isSaving ? '$withFolder  ·  Saving…' : withFolder;
  }

  String _resolveFolderName(int folderId) {
    if (folderId == 0 || !Get.isRegistered<FolderController>()) return '';
    final folders = Get.find<FolderController>().folders;
    final match = _findFolder(folders, folderId);
    return match?.name ?? '';
  }

  Folder? _findFolder(List<Folder> folders, int id) {
    for (final f in folders) {
      if (f.id == id) return f;
      final nested = _findFolder(f.subFolders, id);
      if (nested != null) return nested;
    }
    return null;
  }
}

/// Aa / Checklist / Attachment / Camera / Drawing — always visible together
/// (no idle/expanded split, matching the spec's single fixed row) and swaps
/// out for the format panel rather than ever sharing space with it.
class _BottomToolbar extends StatelessWidget {
  final NoteDetailController controller;

  const _BottomToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: _MaxWidth(
          child: CustomGlassContainer(
            borderRadius: 28,
            blur: 35,
            opacity: 0.1,
            showGlow: true,
            thickness: 10,
            animateLiquid: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            // FIX: Flexible/spaceEvenly instead of a fixed-width Row so this
            // never RenderFlex-overflows on the narrowest iPhone widths.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolbarAaButton(onTap: controller.toggleFormatPanel),
                _ToolbarIcon(
                  icon: CupertinoIcons.checkmark_square,
                  semanticLabel: 'Checklist',
                  onTap: controller.addChecklistBlock,
                ),
                NoteAttachmentPopup(
                  onAction: (type) => _handleAttachmentAction(context, type),
                  trigger: const _ToolbarIconTrigger(
                    icon: CupertinoIcons.paperclip,
                    semanticLabel: 'Attachment',
                  ),
                ),
                _ToolbarIcon(
                  icon: CupertinoIcons.camera,
                  semanticLabel: 'Camera',
                  onTap: () => controller.addAttachment(ImageSource.camera),
                ),
                _ToolbarIcon(
                  icon: CupertinoIcons.pencil_outline,
                  semanticLabel: 'Drawing',
                  onTap: controller.startDrawing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAttachmentAction(BuildContext context, String type) {
    switch (type) {
      case 'camera':
        controller.addAttachment(ImageSource.camera);
      case 'gallery':
        controller.addAttachment(ImageSource.gallery);
      case 'drawing':
        controller.startDrawing();
      case 'scan_text':
      case 'scan_docs':
        AppSnackbar.info('Coming soon', 'Scanning isn\'t available yet.');
      case 'audio':
        AppSnackbar.info(
          'Coming soon',
          'Audio recording isn\'t available yet.',
        );
      case 'file':
        controller.addFileAttachment();
    }
  }
}

class _ToolbarAaButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ToolbarAaButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      label: 'Formatting',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text(
              'Aa',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _ToolbarIcon({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: Icon(icon, size: 24, color: color)),
        ),
      ),
    );
  }
}

/// Same look as [_ToolbarIcon] but with no gesture handling of its own —
/// [NoteAttachmentPopup]'s GlassMenu wraps this in its own tap detector and
/// morphs it directly into the pull-down menu; a second GestureDetector here
/// would only fight it for the tap (see note_editor_toolbar.dart's identical
/// _ToolbarTriggerIcon for the same reasoning).
class _ToolbarIconTrigger extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;

  const _ToolbarIconTrigger({required this.icon, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(child: Icon(icon, size: 24, color: color)),
      ),
    );
  }
}

/// Caps content width on iPad so the editor doesn't stretch edge-to-edge on
/// a wide screen — same pattern used throughout the rest of the app.
class _MaxWidth extends StatelessWidget {
  final Widget child;
  const _MaxWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
