import 'package:flutter/material.dart';

class SplashLoadingStatus extends StatelessWidget {
  const SplashLoadingStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colors.primary,
              backgroundColor: colors.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Starting application...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
