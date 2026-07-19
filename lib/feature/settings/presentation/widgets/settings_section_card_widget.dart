import 'package:flutter/material.dart';

class SettingsSectionCardWidget
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const SettingsSectionCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color:
          colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.18 : 0.35,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.14 : 0.045,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style:
            theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style:
            theme.textTheme.bodyMedium?.copyWith(
              color:
              colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}