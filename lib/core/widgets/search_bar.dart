import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notes/app/theme/colors.dart';

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
    final isDark = theme.brightness == Brightness.dark;

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
                child: const Icon(
                  CupertinoIcons.back,
                  color: AppColors.orange,
                  size: 28,
                ),
              ),
            Expanded(
              child: CupertinoSearchTextField(
                onChanged: onChanged,
                onTap: onTap,
                placeholder: 'Search',
                borderRadius: BorderRadius.circular(10),
                backgroundColor: backgroundColor ?? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                placeholderStyle: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black45,
                  fontSize: 17,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 17,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
            if (showCancelButton)
              CupertinoButton(
                padding: const EdgeInsets.only(left: 12),
                onPressed: onCancel,
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.orange, fontSize: 17),
                ),
              ),
          ],
        ),
        if (token != null) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  token!,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
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
                    color: isDark ? Colors.white60 : Colors.black45,
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
