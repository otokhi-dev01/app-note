import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'recycle_bin_status_state_widget.dart';

class RecycleBinErrorStateWidget extends StatelessWidget {
  const RecycleBinErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return RecycleBinStatusStateWidget(
      icon: CupertinoIcons.exclamationmark_circle_fill,
      iconColor: colors.onErrorContainer,
      iconBackgroundColor: colors.errorContainer,
      title: 'Unable to Load Recycle Bin',
      message: message.isEmpty
          ? 'Something went wrong while loading the recycle bin.'
          : message,
      topPadding: 20,
      titleMessageSpacing: 9,
      actionSpacing: 20,
      action: FilledButton.tonalIcon(
        onPressed: () {
          onRetry();
        },
        icon: const Icon(CupertinoIcons.refresh),
        label: const Text('Try Again'),
      ),
    );
  }
}
