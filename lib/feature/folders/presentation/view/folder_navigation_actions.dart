part of 'folder_list_view.dart';

class _NavigationActions extends StatelessWidget {
  final VoidCallback onSortPressed;
  final VoidCallback onCreatePressed;

  const _NavigationActions({
    required this.onSortPressed,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _GlassNavigationButton(
          icon: CupertinoIcons.arrow_up_arrow_down,
          label: 'Sort folders',
          onPressed: onSortPressed,
        ),
        const SizedBox(width: 7),
        _GlassNavigationButton(
          icon: CupertinoIcons.folder_badge_plus,
          label: 'Create folder',
          primary: true,
          onPressed: onCreatePressed,
        ),
      ],
    );
  }
}
