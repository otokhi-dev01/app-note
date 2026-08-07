import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
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
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        isKeyboardVisible ? 8 : 12,
      ),
      child: SafeArea(
        child: LiquidGlassContainer(
          borderRadius: 30,
          blur: 15,
          opacity: 0.15,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
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
                      ),
                      _ToolbarButton(
                        icon: CupertinoIcons.table,
                        onTap: controller.addTableBlock,
                      ),
                      _ToolbarButton(
                        icon: CupertinoIcons.paperclip,
                        onTap: onShowAttachmentPopup,
                      ),
                    ],
                  ),
                ),
              ],
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

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      width: 40,
      height: 40,
      borderRadius: 20,
      opacity: 0.1,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onTap,
        icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
      ),
    );
  }
}
