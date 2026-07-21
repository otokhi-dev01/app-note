import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoteNavigationIconButton extends StatelessWidget {
  const NoteNavigationIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.buttonSize = 35,
    this.iconSize = 21,
  });

  const NoteNavigationIconButton.editor({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : buttonSize = 36,
       iconSize = 22;

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double buttonSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: SizedBox.square(
        dimension: buttonSize,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          pressedOpacity: 0.45,
          onPressed: onPressed,
          child: Icon(
            icon,
            size: iconSize,
            color: onPressed == null
                ? colors.onSurfaceVariant.withValues(alpha: 0.35)
                : colors.primary,
          ),
        ),
      ),
    );
  }
}
