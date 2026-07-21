import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthPasswordVisibilityButtonWidget extends StatelessWidget {
  const AuthPasswordVisibilityButtonWidget({
    super.key,
    required this.isObscured,
    required this.onPressed,
  });

  final bool isObscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Icon(
        isObscured ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
        size: 21,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
