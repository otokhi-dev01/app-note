import 'package:flutter/material.dart';

class RecycleBinFooterWidget extends StatelessWidget {
  const RecycleBinFooterWidget({
    super.key,
    required this.folderCount,
    required this.noteCount,
  });

  final int folderCount;
  final int noteCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int totalCount = folderCount + noteCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        '$totalCount ${totalCount == 1 ? 'item' : 'items'}',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
