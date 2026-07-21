import 'package:flutter/material.dart';

class SettingsSectionCardWidget extends StatelessWidget {
  const SettingsSectionCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.18 : 0.35),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  spreadRadius: -8,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 21, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colors.outlineVariant.withValues(
              alpha: isDark ? 0.18 : 0.35,
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}
