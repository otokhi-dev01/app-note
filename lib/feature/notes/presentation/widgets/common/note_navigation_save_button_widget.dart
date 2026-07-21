import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoteNavigationSaveButton extends StatelessWidget {
  const NoteNavigationSaveButton({
    super.key,
    required this.saving,
    required this.onPressed,
    this.enabled,
    this.padding = const EdgeInsets.fromLTRB(7, 6, 2, 6),
  });

  const NoteNavigationSaveButton.editor({
    super.key,
    required this.saving,
    required this.enabled,
    required this.onPressed,
  }) : padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6);

  final bool saving;
  final bool? enabled;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isEnabled = enabled ?? onPressed != null;

    return CupertinoButton(
      padding: padding,
      pressedOpacity: 0.5,
      onPressed: isEnabled ? onPressed : null,
      child: saving
          ? CupertinoActivityIndicator(radius: 9, color: colors.primary)
          : Text(
              'Save',
              style: TextStyle(
                color: isEnabled
                    ? colors.primary
                    : colors.onSurfaceVariant.withValues(alpha: 0.4),
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
