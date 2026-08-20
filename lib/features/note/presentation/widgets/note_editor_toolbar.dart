import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';

class NoteEditorToolbar extends StatelessWidget {
  final NoteDetailController controller;
  final VoidCallback onShowAttachmentPopup;

  const NoteEditorToolbar({
    super.key,
    required this.controller,
    required this.onShowAttachmentPopup,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    // Smooth animation for following the keyboard
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutQuad,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          isKeyboardVisible ? 8 : 20, // Clean floating padding
        ),
        child: _PageContent(
          child: isKeyboardVisible
              ? _ExpandedToolbar(
                  controller: controller,
                  onShowAttachmentPopup: onShowAttachmentPopup,
                )
              : _IdleToolbar(
                  controller: controller,
                  onShowAttachmentPopup: onShowAttachmentPopup,
                ),
        ),
      ),
    );
  }
}

/// The compact bar shown while the note isn't actively being typed into: a
/// pill of quick actions plus a separate circular accent button that jumps
/// straight into composing a new note — same floating split-bar footprint
/// as the note list screen's bottom bar.
class _IdleToolbar extends StatelessWidget {
  final NoteDetailController controller;
  final VoidCallback onShowAttachmentPopup;

  const _IdleToolbar({
    required this.controller,
    required this.onShowAttachmentPopup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomGlassContainer(
          borderRadius: 30,
          blur: 35,
          opacity: 0.1,
          showGlow: true,
          thickness: 10,
          animateLiquid: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ToolbarButton(
                  icon: Icons.checklist_rounded,
                  onTap: controller.addChecklistBlock,
                  semanticLabel: 'Checklist',
                ),
                const SizedBox(width: 6),
                _ToolbarButton(
                  icon: CupertinoIcons.paperclip,
                  onTap: onShowAttachmentPopup,
                  semanticLabel: 'Attachment',
                ),
                const SizedBox(width: 6),
                _ToolbarButton(
                  icon: CupertinoIcons.pencil,
                  onTap: controller.toggleFormatPanel,
                  semanticLabel: 'Format',
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        CustomGlassButton(
          onPressed: controller.createNewNote,
          semanticLabel: 'Create note',
          width: 50,
          height: 50,
          shape: GlassShape.circle,
          blur: 10,
          opacity: 0.15,
          thickness: 8,
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.square_pencil,
            color: theme.primaryColor,
            size: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// The wider bar shown once the keyboard is up and the note is actively
/// being edited — a single scrollable row of every editing tool (format,
/// checklist, table, attachment, drawing), matching the Notes-style
/// accessory bar that sits right above the keyboard.
class _ExpandedToolbar extends StatelessWidget {
  final NoteDetailController controller;
  final VoidCallback onShowAttachmentPopup;

  const _ExpandedToolbar({
    required this.controller,
    required this.onShowAttachmentPopup,
  });

  @override
  Widget build(BuildContext context) {
    return CustomGlassContainer(
      borderRadius: 24,
      blur: 35,
      opacity: 0.1,
      showGlow: true,
      thickness: 10,
      animateLiquid: true,
      child: SingleChildScrollView(
        // scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ToolbarButton(
              icon: CupertinoIcons.textformat,
              onTap: controller.toggleFormatPanel,
              semanticLabel: 'Format',
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.checklist_rounded,
              onTap: controller.addChecklistBlock,
              semanticLabel: 'Checklist',
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.table_chart_outlined,
              onTap: controller.addTableBlock,
              semanticLabel: 'Table',
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: CupertinoIcons.paperclip,
              onTap: onShowAttachmentPopup,
              semanticLabel: 'Attachment',
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: CupertinoIcons.pencil_circle,
              onTap: controller.startDrawing,
              semanticLabel: 'Drawing',
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onTap,
          icon: Icon(
            icon,
            color: Theme.of(
              context,
            ).colorScheme.onSurface, // Uses adaptive theme color
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final Widget child;
  const _PageContent({required this.child});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
