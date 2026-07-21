part of 'folder_list_view.dart';

class _FolderStatusView extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconForegroundColor;
  final String title;
  final String message;
  final Widget action;
  final EdgeInsetsGeometry padding;
  final double? messageHeight;
  final double actionSpacing;

  const _FolderStatusView({
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconForegroundColor,
    required this.title,
    required this.message,
    required this.action,
    required this.padding,
    this.messageHeight,
    this.actionSpacing = 20,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 36, color: iconForegroundColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: messageHeight,
              ),
            ),
            SizedBox(height: actionSpacing),
            action,
          ],
        ),
      ),
    );
  }
}
