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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: SafeArea(
        top: false,
        child: AppGlassSurface(
          borderRadius: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tintColor: colors.surface.withValues(alpha: isDark ? 0.65 : 0.75),
          blur: 28,
          child: SizedBox(
            height: 56,
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
      ),
    );
  }
}
