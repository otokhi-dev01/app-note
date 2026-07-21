import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'recycle_bin_status_state_widget.dart';

class EmptyRecycleBinStateWidget extends StatelessWidget {
  const EmptyRecycleBinStateWidget({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return RecycleBinStatusStateWidget(
      icon: CupertinoIcons.delete,
      iconColor: colors.onPrimaryContainer,
      iconBackgroundColor: colors.primaryContainer,
      title: 'Recycle Bin Is Empty',
      message: 'Deleted folders and archived notes will appear here.',
      topPadding: 30,
      titleMessageSpacing: 8,
      actionSpacing: 16,
      action: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onPressed: () {
          onRefresh();
        },
        child: Text(
          'Refresh',
          style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
