import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';

class DecorativeBackground extends StatelessWidget {
  final Widget child;

  const DecorativeBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        // Decorative Background Elements
        Positioned(
          top: -size.height * 0.1,
          right: -size.width * 0.2,
          child: _buildCircle(size.width * 0.8, AppColors.accent.withValues(alpha: 0.08)),
        ),
        Positioned(
          bottom: -size.height * 0.05,
          left: -size.width * 0.1,
          child: _buildCircle(size.width * 0.6, AppColors.primary.withValues(alpha: 0.05)),
        ),
        child,
      ],
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
