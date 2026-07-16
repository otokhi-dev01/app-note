import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoteSearchBar extends StatelessWidget {
  const NoteSearchBar({
    super.key,
    required this.onChanged,
    this.backgroundColor,
    this.onTap,
    this.onCancel,
    this.onBack,
    this.showCancelButton = false,
    this.token,
    this.onTokenRemove,
  });

  final ValueChanged<String> onChanged;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onBack;
  final bool showCancelButton;
  final String? token;
  final VoidCallback? onTokenRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null)
              CupertinoButton(
                padding: const EdgeInsets.only(right: 8),
                onPressed: onBack,
                child: Icon(
                  CupertinoIcons.back,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
            Expanded(
              child: CupertinoSearchTextField(
                onChanged: onChanged,
                onTap: onTap,
                placeholder: 'Search',
                borderRadius: BorderRadius.circular(10),
                backgroundColor: backgroundColor ?? scheme.surfaceContainer,
                placeholderStyle: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 16,
                ),
                style: TextStyle(color: scheme.onSurface, fontSize: 16),
                itemColor: scheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
            ),
            if (showCancelButton)
              CupertinoButton(
                padding: const EdgeInsets.only(left: 12),
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 17,
                  ),
                ),
              ),
          ],
        ),
        if (token != null) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  token!,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onTokenRemove,
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
