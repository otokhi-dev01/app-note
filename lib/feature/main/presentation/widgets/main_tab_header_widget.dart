import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MainTabHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;
  final VoidCallback? onAdd;
  final IconData addIcon;

  const MainTabHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
    this.onAdd,
    this.addIcon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color backgroundColor = isDark
        ? const Color(0xFF1B1D22).withValues(
      alpha: 0.76,
    )
        : Colors.white.withValues(alpha: 0.72);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            15,
            10,
            15,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outlineVariant
                  .withValues(
                alpha: isDark ? 0.22 : 0.34,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.20 : 0.06,
                ),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme
                          .textTheme.headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme
                          .textTheme.bodyMedium
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                _HeaderButton(
                  icon: Icons.refresh_rounded,
                  onPressed: onRefresh!,
                ),
              if (onAdd != null) ...<Widget>[
                const SizedBox(width: 5),
                _HeaderButton(
                  icon: addIcon,
                  onPressed: onAdd!,
                  highlighted: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool highlighted;

  const _HeaderButton({
    required this.icon,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(
            alpha: 0.06,
          ),
          border: Border.all(
            color: highlighted
                ? colorScheme.primary
                : colorScheme.outlineVariant
                .withValues(alpha: 0.28),
          ),
        ),
        child: Icon(
          icon,
          size: 21,
          color: highlighted
              ? colorScheme.onPrimary
              : colorScheme.onSurface,
        ),
      ),
    );
  }
}