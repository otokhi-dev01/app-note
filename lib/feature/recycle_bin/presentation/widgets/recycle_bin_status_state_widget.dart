import 'package:flutter/material.dart';

class RecycleBinStatusStateWidget extends StatelessWidget {
  const RecycleBinStatusStateWidget({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.message,
    required this.action,
    required this.actionSpacing,
    required this.topPadding,
    required this.titleMessageSpacing,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String message;
  final Widget action;
  final double actionSpacing;
  final double topPadding;
  final double titleMessageSpacing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(30, topPadding, 30, 100),
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
              child: Icon(icon, size: 36, color: iconColor),
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
            SizedBox(height: titleMessageSpacing),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
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
