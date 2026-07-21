part of 'folder_list_view.dart';

class _SortAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  const _SortAction({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color foreground = selected ? colors.primary : colors.onSurface;

    return CupertinoActionSheetAction(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 9),
          Text(
            title,
            style: TextStyle(
              color: foreground,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (selected) ...<Widget>[
            const SizedBox(width: 9),
            Icon(CupertinoIcons.check_mark, size: 17, color: colors.primary),
          ],
        ],
      ),
    );
  }
}
