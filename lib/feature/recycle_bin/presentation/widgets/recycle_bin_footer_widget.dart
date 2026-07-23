import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RecycleBinFooterWidget extends StatelessWidget {
  final VoidCallback onEmptyTrash;

  const RecycleBinFooterWidget({
    super.key,
    required this.onEmptyTrash,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Text(
              'Notes in trash will be deleted automatically after 30 days.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onEmptyTrash,
              child: Text(
                'Empty Trash',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
