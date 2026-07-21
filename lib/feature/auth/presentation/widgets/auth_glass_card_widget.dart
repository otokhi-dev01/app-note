import 'dart:ui';
import 'package:flutter/material.dart';

class AuthGlassCardWidget extends StatelessWidget {
  final Widget child;

  const AuthGlassCardWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool isDark = theme.brightness == Brightness.dark;

    final Color cardColor = isDark
        ? const Color(0xFF1B1D22).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.77);

    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.86);

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: borderColor, width: 0.9),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                blurRadius: 40,
                offset: const Offset(0, 22),
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.08 : 0.05,
                ),
                blurRadius: 28,
                offset: const Offset(-10, -8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
