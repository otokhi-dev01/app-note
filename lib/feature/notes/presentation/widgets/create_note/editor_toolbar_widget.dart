part of '../../view/create_note_view.dart';

class _EditorToolbar extends StatelessWidget {
  final VoidCallback onChecklist;
  final VoidCallback onFolder;
  final VoidCallback onCamera;
  final VoidCallback onPhotos;
  final VoidCallback onAttachment;

  const _EditorToolbar({
    required this.onChecklist,
    required this.onFolder,
    required this.onCamera,
    required this.onPhotos,
    required this.onAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final bool isDark = theme.brightness == Brightness.dark;

    final Color toolbarColor = isDark ? const Color(0xFF1B1D22) : Colors.white;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: toolbarColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.outlineVariant.withValues(
                alpha: isDark ? 0.18 : 0.35,
              ),
            ),
            boxShadow: isDark
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      spreadRadius: -8,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _ToolbarButton(
                icon: CupertinoIcons.checkmark_square,
                label: 'Checklist',
                onPressed: onChecklist,
              ),
              _ToolbarButton(
                icon: CupertinoIcons.folder,
                label: 'Folder',
                onPressed: onFolder,
              ),
              _ToolbarButton(
                icon: CupertinoIcons.camera,
                label: 'Camera',
                onPressed: onCamera,
              ),
              _ToolbarButton(
                icon: CupertinoIcons.photo_on_rectangle,
                label: 'Photos',
                onPressed: onPhotos,
              ),
              _ToolbarButton(
                icon: CupertinoIcons.paperclip,
                label: 'Attachment',
                highlighted: true,
                onPressed: onAttachment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
