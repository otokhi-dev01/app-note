import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RegisterTopBarWidget extends StatelessWidget {
  const RegisterTopBarWidget({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface.withValues(alpha: 0.68),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.32),
                ),
              ),
              child: Icon(
                CupertinoIcons.back,
                size: 21,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
