import 'package:flutter/material.dart';

import 'recycle_bin_item_icon_widget.dart';
import 'recycle_bin_restore_button_widget.dart';

class RecycleBinItemRowWidget extends StatelessWidget {
  const RecycleBinItemRowWidget({
    super.key,
    required this.icon,
    required this.iconForegroundColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.description,
    required this.onRestore,
  });

  final IconData icon;
  final Color iconForegroundColor;
  final Color iconBackgroundColor;
  final String title;
  final String description;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
      child: Row(
        children: <Widget>[
          RecycleBinItemIconWidget(
            icon: icon,
            foregroundColor: iconForegroundColor,
            backgroundColor: iconBackgroundColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RecycleBinRestoreButtonWidget(onPressed: onRestore),
        ],
      ),
    );
  }
}
