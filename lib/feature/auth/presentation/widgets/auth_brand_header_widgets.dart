import 'package:flutter/material.dart';

class AuthBrandHeaderWidgets extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final String description;
  final double imageSize;

  const AuthBrandHeaderWidgets({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.description,
    this.imageSize = 82,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark =
        theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1B1D22)
                : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: isDark ? 0.22 : 0.40,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.22 : 0.18,
                ),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.20 : 0.06,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                  ) {
                return Icon(
                  Icons.note_alt_rounded,
                  size: imageSize * 0.48,
                  color: colorScheme.primary,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}