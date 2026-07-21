import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileMenuTileWidget extends StatelessWidget {
  const ProfileMenuTileWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accentColor = isDestructive ? colors.error : colors.primary;
    final Color titleColor = isDestructive ? colors.error : colors.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accentColor.withValues(alpha: 0.08),
        highlightColor: accentColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 17,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.65),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
