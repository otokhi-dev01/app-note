import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'recycle_bin_item_icon_widget.dart';
import 'recycle_bin_summary_count_widget.dart';
import 'recycle_bin_surface_widget.dart';

class RecycleBinSummaryWidget extends StatelessWidget {
  const RecycleBinSummaryWidget({
    super.key,
    required this.folderCount,
    required this.noteCount,
  });

  final int folderCount;
  final int noteCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int totalCount = folderCount + noteCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      child: RecycleBinSurfaceWidget(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                RecycleBinItemIconWidget(
                  icon: CupertinoIcons.delete,
                  foregroundColor: colors.primary,
                  backgroundColor: colors.primaryContainer,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$totalCount ${totalCount == 1 ? 'Item' : 'Items'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Restore folders and notes that you still need.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Divider(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 13),
            Row(
              children: <Widget>[
                Expanded(
                  child: RecycleBinSummaryCountWidget(
                    icon: CupertinoIcons.folder_fill,
                    label: 'Folders',
                    count: folderCount,
                  ),
                ),
                Container(width: 1, height: 36, color: colors.outlineVariant),
                Expanded(
                  child: RecycleBinSummaryCountWidget(
                    icon: CupertinoIcons.archivebox_fill,
                    label: 'Notes',
                    count: noteCount,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
