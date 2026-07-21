import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthMessageBoxWidget extends StatelessWidget {
  final String message;
  final bool isError;

  const AuthMessageBoxWidget({
    super.key,
    required this.message,
    this.isError = true,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color mainColor = isError ? colorScheme.error : colorScheme.primary;

    final Color backgroundColor = isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    final Color foregroundColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isError
                ? CupertinoIcons.exclamationmark_circle
                : CupertinoIcons.checkmark_circle,
            size: 20,
            color: mainColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foregroundColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
