import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/note_detail_controller.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
          child: LiquidGlassContainer(
            borderRadius: 30,
            blur: 25,
            opacity: isDark ? 0.8 : 0.98, // Professional iOS feel
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ToolbarButton(
                          icon: CupertinoIcons.list_bullet,
                          onTap: controller.addChecklistBlock,
                          semanticLabel: 'Checklist',
                        ),
                        _ToolbarButton(
                          icon: CupertinoIcons.table,
                          onTap: controller.addTableBlock,
                          semanticLabel: 'Table',
                        ),
                        _ToolbarButton(
                          icon: CupertinoIcons.paperclip,
                          onTap: onShowAttachmentPopup,
                          semanticLabel: 'Attachment',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onTap,
          icon: Icon(
            icon, 
            color: Theme.of(context).colorScheme.onSurface, // Uses adaptive theme color
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
