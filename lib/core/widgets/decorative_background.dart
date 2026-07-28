import 'package:flutter/material.dart';

class DecorativeBackground extends StatelessWidget {
  final Widget child;

  const DecorativeBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? const Color(0xFF000000) : Colors.white,
      child: Stack(
        children: [
          // Top Right - Soft Modern Indigo/Purple
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: _buildCircle(
              size.width * 0.8,
              (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF8B5CF6)).withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ),
          // Bottom Left - Clean Cool Cyan/Teal
          Positioned(
            bottom: -size.height * 0.05,
            left: -size.width * 0.1,
            child: _buildCircle(
              size.width * 0.6,
              (isDark ? const Color(0xFF06B6D4) : const Color(0xFF06B6D4)).withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ),
          // Foreground Content
          child,
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}