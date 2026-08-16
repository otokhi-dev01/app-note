import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
          child: CustomGlassContainer(
            borderRadius: 30,
            blur: 35,
            opacity: 0.1, // Premium translucent feel
            showGlow: true,
            thickness: 10,
            animateLiquid: true, // FEATURE: Added premium liquid glass physics
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ToolbarButton(
                          icon: Icons.text_fields_rounded,
                          onTap: controller.toggleFormatPanel,
                          semanticLabel: 'Format',
                        ),
                        _ToolbarButton(
                          icon: CupertinoIcons.pencil_outline,
                          onTap: controller.startDrawing, // Launches high-power native editor
                          semanticLabel: 'Pencil',
                        ),
                        _ToolbarButton(
                          icon: CupertinoIcons.paperclip,
                          onTap: onShowAttachmentPopup,
                          semanticLabel: 'Attachment',
                        ),
                        _ToolbarButton(
                          icon: CupertinoIcons.camera,
                          onTap: () =>
                              controller.addAttachment(ImageSource.camera),
                          semanticLabel: 'Camera',
                        ),
                        _ToolbarButton(
                          icon: CupertinoIcons.photo,
                          onTap: () =>
                              controller.addAttachment(ImageSource.gallery),
                          semanticLabel: 'Photo',
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
