part of '../../view/create_note_view.dart';

class _EditorToolbar extends GetView<CreateNoteController> {
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SafeArea(
        top: false,
        child: AppGlassSurface(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tintColor: colors.surface.withValues(alpha: isDark ? 0.75 : 0.85),
          blur: 28,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _ToolbarIcon(
                  icon: CupertinoIcons.textformat,
                  onPressed: () => controller.insertToStatement('**Text**'),
                ),
                _ToolbarIcon(
                  icon: CupertinoIcons.list_bullet_indent,
                  onPressed: () => controller.insertToStatement('\n1. '),
                ),
                _ToolbarIcon(
                  icon: CupertinoIcons.checkmark_square,
                  onPressed: onChecklist,
                ),
                _ToolbarIcon(
                  icon: CupertinoIcons.photo,
                  onPressed: onPhotos,
                ),
                _ToolbarIcon(
                  icon: CupertinoIcons.link,
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

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ToolbarIcon({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Icon(
        icon,
        size: 20,
        color: colors.onSurface.withValues(alpha: 0.8),
      ),
    );
  }
}
