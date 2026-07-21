import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthSecurityNoticeWidget extends StatelessWidget {
  const AuthSecurityNoticeWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          CupertinoIcons.lock_shield,
          size: 15,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
