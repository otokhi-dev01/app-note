import 'package:flutter/material.dart';

/// Keeps field labels, validation, counters, and icons inside the shared surface.
InputDecoration glassInputDecoration(InputDecoration decoration) =>
    decoration.copyWith(
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding:
          decoration.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

/// The rounded input surface shared by account fields and other form controls.
class GlassInputSurface extends StatelessWidget {
  const GlassInputSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.height,
    this.minHeight,
    this.maxHeight,
  }) : assert(height == null || (minHeight == null && maxHeight == null));

  final Widget child;
  final double borderRadius;
  final double? height;
  final double? minHeight;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: height,
      constraints: height == null
          ? BoxConstraints(
              minHeight: minHeight ?? 0,
              maxHeight: maxHeight ?? double.infinity,
            )
          : null,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : const Color(0xFFF1F0F7),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.75),
              blurRadius: 10,
              offset: const Offset(-3, -3),
            ),
        ],
      ),
      child: child,
    );
  }
}
