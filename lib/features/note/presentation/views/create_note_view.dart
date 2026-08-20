import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_block_list.dart';
import 'package:Note/features/note/presentation/widgets/note_editor_header.dart';
import 'package:Note/features/note/presentation/widgets/note_editor_toolbar.dart';
import 'package:Note/features/note/presentation/widgets/note_editor_top_bar.dart';
import 'package:Note/features/note/presentation/widgets/note_format_panel.dart';

/// The dedicated screen for composing a brand-new note (`noteId == 0`).
/// Opening an *existing* note uses NoteDetailView/NoteContentEditor — see
/// NoteNavigation.toNewNote (routes here) vs .toDetail (routes there).
///
/// Both screens are meant to look like one editor, so the chrome is shared
/// outright rather than reimplemented here: [NoteEditorTopBar] for the
/// back/undo/share/more/save row, [NoteEditorHeader] for the timestamp and
/// folder line, and [NoteEditorToolbar] for the bar above the keyboard. What
/// stays local is only what genuinely differs for an unsaved note — see
/// `_handleBack`.
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
            // Title, header and blocks, under a top bar that is a sliver in
            // the same scroll view (not a floating overlay) so it behaves
            // exactly as it does on the edit screen.
            _CreateNoteBody(controller: controller),

            // The toolbar tracks the keyboard inset itself, so it is aligned
            // to the bottom rather than positioned against that inset here —
            // doing both would apply the keyboard height twice. The format
            // panel has no such handling of its own and gets the inset
            // applied explicitly.
            Obx(() {
              if (controller.isReadOnly.value) {
                return const SizedBox.shrink();
              }
              return Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  // The format panel replaces the toolbar outright instead of
                  // stacking on top of it, so the two can never overlap.
                  child: controller.isFormatPanelVisible.value
                      ? Padding(
                          key: const ValueKey('format-panel'),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          child: NoteFormatPanel(controller: controller),
                        )
                      : NoteEditorToolbar(
                          key: const ValueKey('bottom-toolbar'),
                          controller: controller,
                          onAttachmentAction: (type) =>
                              _handleAttachmentAction(type),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _handleAttachmentAction(String type) {
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

/// Back must never bring a blank note into existence: `saveAndExitIfNeeded`
/// is a pure no-op when there's nothing worth saving, so opening this screen
/// and immediately leaving writes nothing. This is the one behavior the shared
/// [NoteEditorTopBar] can't default to — for a note that already exists, its
/// Back saves unconditionally.
Future<void> _handleBack(NoteDetailController controller) async {
  await controller.saveAndExitIfNeeded();
  Get.back(result: true);
}

/// The scrolling editor: shared top bar, the timestamp/folder header, the
/// title field, then the blocks.
class _CreateNoteBody extends StatelessWidget {
  final NoteDetailController controller;

  const _CreateNoteBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Matches NoteContentEditor's own inset so a note doesn't shift sideways
    // between being created and being reopened.
    final horizontalInset = (MediaQuery.sizeOf(context).width * 0.065).clamp(
      21.0,
      32.0,
    );
    // Enough that the last line is never hidden behind the floating toolbar —
    // 140 covers its height plus its margin, and the keyboard inset is added
    // on top so the gap grows whenever the keyboard is up.
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 140;

    return _MaxWidth(
      child: Obx(() {
        final isReadOnly = controller.isReadOnly.value;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Manual dismiss (not onDrag) so scrolling the note while actively
          // typing doesn't fight the cursor-follows-keyboard behavior.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          slivers: [
            // A sliver in this same scroll view rather than a floating
            // overlay — that's what makes it the same bar as the edit
            // screen's, checkmark and all, instead of a lookalike.
            NoteEditorTopBar(
              controller: controller,
              onBack: () => _handleBack(controller),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                16,
                horizontalInset,
                bottomPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  NoteEditorHeader(controller: controller),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('create-note-title-field'),
                    controller: controller.titleController,
                    enabled: !isReadOnly,
                    // A brand-new note opens with the cursor already in the
                    // title, keyboard up — no extra tap needed to start
                    // typing.
                    autofocus: !isReadOnly,
                    onTap: () => controller.activeBlockIndex.value = -1,
                    cursorColor: AppTheme.folderYellow,
                    cursorWidth: 1.5,
                    maxLines: null,
                    keyboardType: TextInputType.text,
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
                  const SizedBox(height: 12),
                  NoteBlockList(
                    controller: controller,
                    textPlaceholder: 'Start writing...',
                  ),
                  if (!isReadOnly)
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: controller.focusLastTextBlock,
                      child: const SizedBox(
                        height: 250,
                        width: double.infinity,
                      ),
                    ),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Caps content width on iPad so the editor doesn't stretch edge-to-edge on a
/// wide screen. Same 600 cap as NoteContentEditor's, so the two screens lay
/// out identically there too.
class _MaxWidth extends StatelessWidget {
  final Widget child;
  const _MaxWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
