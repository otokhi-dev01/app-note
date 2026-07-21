import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoteNavigationBackButton extends StatelessWidget {
  const NoteNavigationBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      pressedOpacity: 0.45,
      onPressed: onPressed,
      child: Icon(
        CupertinoIcons.back,
        size: 25,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
