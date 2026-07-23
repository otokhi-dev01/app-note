import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RecycleBinRestoreButtonWidget extends StatelessWidget {
  const RecycleBinRestoreButtonWidget({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      pressedOpacity: 0.5,
      borderRadius: BorderRadius.circular(11),
      color: colors.primaryContainer,
      onPressed: onPressed,
      child: Text(
        'Restore',
        style: theme.textTheme.labelMedium?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
