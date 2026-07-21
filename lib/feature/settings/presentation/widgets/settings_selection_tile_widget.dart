import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsSelectionTileWidget extends StatelessWidget {
  const SettingsSelectionTileWidget({
    super.key,
    required this.leading,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.11)
          : colorScheme.surface.withValues(alpha: 0.50),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.55)
                  : colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: <Widget>[
              leading,
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        key: const ValueKey<bool>(true),
                        size: 23,
                        color: colorScheme.primary,
                      )
                    : Icon(
                        CupertinoIcons.circle,
                        key: const ValueKey<bool>(false),
                        size: 23,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.45,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
